const std = @import("std");
const vk = @import("vulkan");
const c = @import("c");
const Allocator = std.mem.Allocator;
const types = @import("types.zig");
const texture = @import("texture.zig");

const required_layer_names = [_][*:0]const u8{"VK_LAYER_KHRONOS_validation"};

const required_device_extensions = [_][*:0]const u8{vk.extensions.khr_swapchain.name};

const BaseWrapper = vk.BaseWrapper;
const InstanceWrapper = vk.InstanceWrapper;
const DeviceWrapper = vk.DeviceWrapper;

const Instance = vk.InstanceProxy;
const Device = vk.DeviceProxy;

pub const StagingContext = struct {
    cmdbuf: vk.CommandBuffer,
    fence: vk.Fence,
    staging_buffers: std.ArrayList(types.Buffer),

    pub fn deinit(self: *StagingContext, gc: *const GraphicsContext) void {
        for (self.staging_buffers.items) |buf| buf.deinit(gc.dev);
        self.staging_buffers.deinit(gc.allocator);
        gc.dev.destroyFence(self.fence, null);
    }
};

pub const GraphicsContext = struct {
    pub const CommandBuffer = vk.CommandBufferProxy;

    allocator: Allocator,

    vkb: BaseWrapper,

    instance: Instance,
    debug_messenger: vk.DebugUtilsMessengerEXT,
    surface: vk.SurfaceKHR,
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    mem_props: vk.PhysicalDeviceMemoryProperties,

    dev: Device,
    graphics_queue: Queue,
    present_queue: Queue,

    pub fn init(allocator: Allocator, app_name: [*:0]const u8, window: *c.SDL_Window) !GraphicsContext {
        var self: GraphicsContext = undefined;
        self.allocator = allocator;
        const sdl_loader = c.SDL_Vulkan_GetVkGetInstanceProcAddr() orelse return error.VulkanLoaderNotFound;
        const LoaderFn = vk.PfnGetInstanceProcAddr;

        self.vkb = BaseWrapper.load(@as(LoaderFn, @ptrCast(sdl_loader)));

        if (try checkLayerSupport(&self.vkb, self.allocator) == false) {
            return error.MissingLayer;
        }

        var extension_names: std.ArrayList([*:0]const u8) = .empty;
        defer extension_names.deinit(allocator);
        try extension_names.append(allocator, vk.extensions.ext_debug_utils.name);

        try extension_names.append(allocator, vk.extensions.khr_portability_enumeration.name);
        try extension_names.append(allocator, vk.extensions.khr_get_physical_device_properties_2.name);

        var sdl_exts_count: u32 = 0;
        const sdl_exts = c.SDL_Vulkan_GetInstanceExtensions(&sdl_exts_count);
        if (sdl_exts == null) return error.SdlVulkanExtensionsNotFound;

        for (sdl_exts[0..sdl_exts_count]) |ext_name| {
            try extension_names.append(allocator, @ptrCast(ext_name));
        }

        const instance = try self.vkb.createInstance(&.{
            .p_application_info = &.{
                .p_application_name = app_name,
                .application_version = @bitCast(vk.makeApiVersion(0, 0, 0, 0)),
                .p_engine_name = app_name,
                .engine_version = @bitCast(vk.makeApiVersion(0, 0, 0, 0)),
                .api_version = @bitCast(vk.API_VERSION_1_2),
            },
            .enabled_layer_count = required_layer_names.len,
            .pp_enabled_layer_names = @ptrCast(&required_layer_names),
            .enabled_extension_count = @intCast(extension_names.items.len),
            .pp_enabled_extension_names = extension_names.items.ptr,
            .flags = .{ .enumerate_portability_bit_khr = true },
        }, null);

        const vki = try allocator.create(InstanceWrapper);
        errdefer allocator.destroy(vki);
        vki.* = InstanceWrapper.load(instance, self.vkb.dispatch.vkGetInstanceProcAddr.?);
        self.instance = Instance.init(instance, vki);
        errdefer self.instance.destroyInstance(null);

        self.debug_messenger = try self.instance.createDebugUtilsMessengerEXT(&.{
            .message_severity = .{
                .warning_bit_ext = true,
                .error_bit_ext = true,
            },
            .message_type = .{
                .general_bit_ext = true,
                .validation_bit_ext = true,
                .performance_bit_ext = true,
            },
            .pfn_user_callback = &debugUtilsMessengerCallback,
            .p_user_data = null,
        }, null);

        self.surface = try createSurface(self.instance, window);
        errdefer self.instance.destroySurfaceKHR(self.surface, null);

        const candidate = try pickPhysicalDevice(self.instance, allocator, self.surface);
        self.pdev = candidate.pdev;
        self.props = candidate.props;

        const dev = try initializeCandidate(self.instance, candidate);

        const vkd = try allocator.create(DeviceWrapper);
        errdefer allocator.destroy(vkd);
        vkd.* = DeviceWrapper.load(dev, self.instance.wrapper.dispatch.vkGetDeviceProcAddr.?);
        self.dev = Device.init(dev, vkd);
        errdefer self.dev.destroyDevice(null);

        self.graphics_queue = Queue.init(self.dev, candidate.queues.graphics_family);
        self.present_queue = Queue.init(self.dev, candidate.queues.present_family);

        self.mem_props = self.instance.getPhysicalDeviceMemoryProperties(self.pdev);

        return self;
    }

    pub fn deinit(self: GraphicsContext) void {
        self.dev.destroyDevice(null);
        self.instance.destroySurfaceKHR(self.surface, null);
        self.instance.destroyDebugUtilsMessengerEXT(self.debug_messenger, null);
        self.instance.destroyInstance(null);

        self.allocator.destroy(self.dev.wrapper);
        self.allocator.destroy(self.instance.wrapper);
    }

    pub fn uploadData(self: *const GraphicsContext, comptime T: type, pool: vk.CommandPool, buffer: vk.Buffer, data_slice: []const T) !void {
        const size = @sizeOf(T) * data_slice.len;

        const staging_buffer = try self.dev.createBuffer(&.{
            .size = size,
            .usage = .{ .transfer_src_bit = true },
            .sharing_mode = .exclusive,
        }, null);
        defer self.dev.destroyBuffer(staging_buffer, null);

        const mem_reqs = self.dev.getBufferMemoryRequirements(staging_buffer);
        const staging_memory = try self.allocate(mem_reqs, .{ .host_visible_bit = true, .host_coherent_bit = true });
        defer self.dev.freeMemory(staging_memory, null);
        try self.dev.bindBufferMemory(staging_buffer, staging_memory, 0);

        {
            const data_ptr = try self.dev.mapMemory(staging_memory, 0, vk.WHOLE_SIZE, .{});
            defer self.dev.unmapMemory(staging_memory);

            const gpu_ptr: [*]T = @ptrCast(@alignCast(data_ptr));
            @memcpy(gpu_ptr[0..data_slice.len], data_slice);
        }

        try copyBuffer(self, pool, buffer, staging_buffer, size);
    }

    pub fn deviceName(self: *const GraphicsContext) []const u8 {
        return std.mem.sliceTo(&self.props.device_name, 0);
    }

    pub fn findMemoryTypeIndex(self: GraphicsContext, memory_type_bits: u32, flags: vk.MemoryPropertyFlags) !u32 {
        for (self.mem_props.memory_types[0..self.mem_props.memory_type_count], 0..) |mem_type, i| {
            if (memory_type_bits & (@as(u32, 1) << @truncate(i)) != 0 and mem_type.property_flags.contains(flags)) {
                return @truncate(i);
            }
        }

        return error.NoSuitableMemoryType;
    }

    pub fn allocate(self: GraphicsContext, requirements: vk.MemoryRequirements, flags: vk.MemoryPropertyFlags) !vk.DeviceMemory {
        return try self.dev.allocateMemory(&.{
            .allocation_size = requirements.size,
            .memory_type_index = try self.findMemoryTypeIndex(requirements.memory_type_bits, flags),
        }, null);
    }

    pub fn findDepthFormat(self: GraphicsContext) !vk.Format {
        const candidates = [_]vk.Format{ .d32_sfloat, .d32_sfloat_s8_uint, .d24_unorm_s8_uint };
        for (candidates) |format| {
            const props = self.instance.getPhysicalDeviceFormatProperties(self.pdev, format);
            if (props.optimal_tiling_features.depth_stencil_attachment_bit) {
                return format;
            }
        }
        return error.NoSuitableDepthFormat;
    }

    pub fn createBuffer(self: GraphicsContext, size: vk.DeviceSize, usage: vk.BufferUsageFlags, properties: vk.MemoryPropertyFlags) !types.Buffer {
        const handle = try self.dev.createBuffer(&.{
            .size = size,
            .usage = usage,
            .sharing_mode = .exclusive,
        }, null);

        const mem_reqs = self.dev.getBufferMemoryRequirements(handle);
        const memory = try self.allocate(mem_reqs, properties);
        try self.dev.bindBufferMemory(handle, memory, 0);

        return types.Buffer{ .handle = handle, .memory = memory, .size = size };
    }

    pub fn createBufferWithData(self: GraphicsContext, pool: vk.CommandPool, comptime T: type, data: []const T, usage: vk.BufferUsageFlags) !types.Buffer {
        const size = @as(vk.DeviceSize, @intCast(data.len * @sizeOf(T)));

        const staging = try self.createBuffer(size, .{ .transfer_src_bit = true }, .{ .host_visible_bit = true, .host_coherent_bit = true });
        defer staging.deinit(self.dev);

        const ptr = try self.dev.mapMemory(staging.memory, 0, size, .{});
        const gpu_ptr: [*]T = @ptrCast(@alignCast(ptr));
        @memcpy(gpu_ptr[0..data.len], data);
        self.dev.unmapMemory(staging.memory);

        var combined_usage = usage;
        combined_usage.transfer_dst_bit = true;
        const device_buffer = try self.createBuffer(size, combined_usage, .{ .device_local_bit = true });

        try self.copyBuffer(pool, device_buffer.handle, staging.handle, size);

        return device_buffer;
    }

    fn copyBuffer(self: GraphicsContext, pool: vk.CommandPool, dst: vk.Buffer, src: vk.Buffer, size: vk.DeviceSize) !void {
        var cmdbuf_handle: vk.CommandBuffer = undefined;
        try self.dev.allocateCommandBuffers(&.{
            .command_pool = pool,
            .level = .primary,
            .command_buffer_count = 1,
        }, @ptrCast(&cmdbuf_handle));
        defer self.dev.freeCommandBuffers(pool, 1, @ptrCast(&cmdbuf_handle));

        const cmdbuf = GraphicsContext.CommandBuffer.init(cmdbuf_handle, self.dev.wrapper);

        try cmdbuf.beginCommandBuffer(&.{ .flags = .{ .one_time_submit_bit = true } });
        cmdbuf.copyBuffer(src, dst, 1, @ptrCast(&vk.BufferCopy{
            .src_offset = 0,
            .dst_offset = 0,
            .size = size,
        }));
        try cmdbuf.endCommandBuffer();

        try self.dev.queueSubmit(self.graphics_queue.handle, 1, @ptrCast(&vk.SubmitInfo{
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&cmdbuf.handle),
        }), .null_handle);

        try self.dev.queueWaitIdle(self.graphics_queue.handle);
    }

    pub fn beginStaging(self: *const GraphicsContext, pool: vk.CommandPool) !StagingContext {
        var cmdbuf_handle: vk.CommandBuffer = undefined;
        try self.dev.allocateCommandBuffers(&.{
            .command_pool = pool,
            .level = .primary,
            .command_buffer_count = 1,
        }, @ptrCast(&cmdbuf_handle));

        const fence = try self.dev.createFence(&.{ .flags = .{} }, null);

        const cmdbuf = GraphicsContext.CommandBuffer.init(cmdbuf_handle, self.dev.wrapper);
        try cmdbuf.beginCommandBuffer(&.{ .flags = .{ .one_time_submit_bit = true } });

        const staging_buffers: std.ArrayList(types.Buffer) = .empty;

        return StagingContext{
            .cmdbuf = cmdbuf_handle,
            .fence = fence,
            .staging_buffers = staging_buffers,
        };
    }

    pub fn createBufferDeferred(self: *const GraphicsContext, staging: *StagingContext, comptime T: type, data: []const T, usage: vk.BufferUsageFlags) !types.Buffer {
        const size = @as(vk.DeviceSize, @intCast(data.len * @sizeOf(T)));

        const staging_buf = try self.createBuffer(size, .{ .transfer_src_bit = true }, .{ .host_visible_bit = true, .host_coherent_bit = true });
        try staging.staging_buffers.append(self.allocator, staging_buf);

        const ptr = try self.dev.mapMemory(staging_buf.memory, 0, size, .{});
        @memcpy(@as([*]T, @ptrCast(@alignCast(ptr)))[0..data.len], data);
        self.dev.unmapMemory(staging_buf.memory);

        var combined_usage = usage;
        combined_usage.transfer_dst_bit = true;
        const device_buf = try self.createBuffer(size, combined_usage, .{ .device_local_bit = true });

        const cmdbuf = GraphicsContext.CommandBuffer.init(staging.cmdbuf, self.dev.wrapper);
        cmdbuf.copyBuffer(staging_buf.handle, device_buf.handle, 1, @ptrCast(&vk.BufferCopy{
            .src_offset = 0,
            .dst_offset = 0,
            .size = size,
        }));

        return device_buf;
    }

    pub fn endStaging(self: *const GraphicsContext, staging: *StagingContext) !void {
        const cmdbuf = GraphicsContext.CommandBuffer.init(staging.cmdbuf, self.dev.wrapper);
        try cmdbuf.endCommandBuffer();

        const si = vk.SubmitInfo{
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&staging.cmdbuf),
        };

        try self.dev.queueSubmit(self.graphics_queue.handle, 1, @ptrCast(&si), staging.fence);

        _ = try self.dev.waitForFences(1, @ptrCast(&staging.fence), vk.Bool32.true, std.math.maxInt(u64));
    }

    pub fn createTextureDeferred(
        self: *const GraphicsContext,
        staging: *StagingContext,
        width: u32,
        height: u32,
        pixels: []const u8,
    ) !texture.Texture {
        const size = @as(vk.DeviceSize, width * height * 4);
        const format = vk.Format.r8g8b8a8_unorm;

        const staging_buf = try self.createBuffer(
            size,
            .{ .transfer_src_bit = true },
            .{ .host_visible_bit = true, .host_coherent_bit = true },
        );
        try staging.staging_buffers.append(self.allocator, staging_buf);

        const ptr = try self.dev.mapMemory(staging_buf.memory, 0, size, .{});
        @memcpy(@as([*]u8, @ptrCast(@alignCast(ptr))), pixels);
        self.dev.unmapMemory(staging_buf.memory);

        const image = try self.dev.createImage(&.{
            .image_type = .@"2d",
            .extent = .{ .width = width, .height = height, .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .format = format,
            .tiling = .optimal,
            .initial_layout = .undefined,
            .usage = .{ .transfer_dst_bit = true, .sampled_bit = true },
            .sharing_mode = .exclusive,
            .samples = .{ .@"1_bit" = true },
        }, null);

        const mem_reqs = self.dev.getImageMemoryRequirements(image);
        const memory = try self.allocate(mem_reqs, .{ .device_local_bit = true });
        try self.dev.bindImageMemory(image, memory, 0);

        const cmdbuf = staging.cmdbuf;

        try texture.Texture.transitionImageLayout(self, cmdbuf, image, .undefined, .transfer_dst_optimal);

        texture.Texture.copyBufferToImage(self, cmdbuf, staging_buf.handle, image, width, height);

        try texture.Texture.transitionImageLayout(self, cmdbuf, image, .transfer_dst_optimal, .shader_read_only_optimal);

        const view = try self.dev.createImageView(&.{
            .image = image,
            .view_type = .@"2d",
            .format = format,
            .components = .{
                .r = .identity,
                .g = .identity,
                .b = .identity,
                .a = .identity,
            },
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        }, null);

        const sampler = try self.dev.createSampler(&.{
            .flags = .{},
            .mag_filter = .nearest,
            .min_filter = .nearest,
            .mipmap_mode = .nearest,
            .address_mode_u = .clamp_to_edge,
            .address_mode_v = .clamp_to_edge,
            .address_mode_w = .clamp_to_edge,
            .mip_lod_bias = 0.0,
            .anisotropy_enable = .false,
            .max_anisotropy = 1.0,
            .compare_enable = .false,
            .compare_op = .always,
            .min_lod = 0.0,
            .max_lod = 0.0,
            .border_color = .float_opaque_black,
            .unnormalized_coordinates = .false,
        }, null);

        return texture.Texture{
            .image = image,
            .memory = memory,
            .view = view,
            .sampler = sampler,
            .width = width,
            .height = height,
        };
    }
};

fn checkLayerSupport(vkb: *const BaseWrapper, alloc: Allocator) !bool {
    const available_layers = try vkb.enumerateInstanceLayerPropertiesAlloc(alloc);
    defer alloc.free(available_layers);
    for (required_layer_names) |required_layer| {
        for (available_layers) |layer| {
            if (std.mem.eql(u8, std.mem.span(required_layer), std.mem.sliceTo(&layer.layer_name, 0))) {
                break;
            }
        } else {
            return false;
        }
    }
    return true;
}

pub const Queue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(device: Device, family: u32) Queue {
        return .{
            .handle = device.getDeviceQueue(family, 0),
            .family = family,
        };
    }
};

fn createSurface(instance: Instance, window: *c.SDL_Window) !vk.SurfaceKHR {
    var surface: vk.SurfaceKHR = undefined;

    const instance_handle: ?*anyopaque = @ptrFromInt(@intFromEnum(instance.handle));

    if (!c.SDL_Vulkan_CreateSurface(window, @ptrCast(instance_handle), null, @ptrCast(&surface)))
        return error.SurfaceInitFailed;

    return surface;
}

fn initializeCandidate(instance: Instance, candidate: DeviceCandidate) !vk.Device {
    const priority = [_]f32{1};
    const qci = [_]vk.DeviceQueueCreateInfo{
        .{
            .queue_family_index = candidate.queues.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &priority,
        },
        .{
            .queue_family_index = candidate.queues.present_family,
            .queue_count = 1,
            .p_queue_priorities = &priority,
        },
    };

    const queue_count: u32 = if (candidate.queues.graphics_family == candidate.queues.present_family)
        1
    else
        2;

    var index_features = vk.PhysicalDeviceDescriptorIndexingFeatures{
        .descriptor_binding_sampled_image_update_after_bind = .true,
        .descriptor_binding_variable_descriptor_count = .true,
        .descriptor_binding_partially_bound = .true,
        .runtime_descriptor_array = .true,
        .shader_sampled_image_array_non_uniform_indexing = .true,
    };

    const features = vk.PhysicalDeviceFeatures{
        .shader_int_16 = .true,
        .sampler_anisotropy = .false,
    };

    return try instance.createDevice(candidate.pdev, &.{
        .queue_create_info_count = queue_count,
        .p_queue_create_infos = &qci,
        .enabled_extension_count = required_device_extensions.len,
        .pp_enabled_extension_names = @ptrCast(&required_device_extensions),
        .p_enabled_features = &features,
        .p_next = &index_features,
    }, null);
}

const DeviceCandidate = struct {
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    queues: QueueAllocation,
};

const QueueAllocation = struct {
    graphics_family: u32,
    present_family: u32,
};

fn debugUtilsMessengerCallback(severity: vk.DebugUtilsMessageSeverityFlagsEXT, msg_type: vk.DebugUtilsMessageTypeFlagsEXT, callback_data: ?*const vk.DebugUtilsMessengerCallbackDataEXT, _: ?*anyopaque) callconv(.c) vk.Bool32 {
    const severity_str = if (severity.verbose_bit_ext) "verbose" else if (severity.info_bit_ext) "info" else if (severity.warning_bit_ext) "warning" else if (severity.error_bit_ext) "error" else "unknown";

    const type_str = if (msg_type.general_bit_ext) "general" else if (msg_type.validation_bit_ext) "validation" else if (msg_type.performance_bit_ext) "performance" else if (msg_type.device_address_binding_bit_ext) "device addr" else "unknown";

    const message: [*c]const u8 = if (callback_data) |cb_data| cb_data.p_message else "NO MESSAGE!";
    std.debug.print("[{s}][{s}]. Message:\n  {s}\n", .{ severity_str, type_str, message });

    return .false;
}

fn pickPhysicalDevice(
    instance: Instance,
    allocator: Allocator,
    surface: vk.SurfaceKHR,
) !DeviceCandidate {
    const pdevs = try instance.enumeratePhysicalDevicesAlloc(allocator);
    defer allocator.free(pdevs);

    for (pdevs) |pdev| {
        if (try checkSuitable(instance, pdev, allocator, surface)) |candidate| {
            return candidate;
        }
    }

    return error.NoSuitableDevice;
}

fn checkSuitable(
    instance: Instance,
    pdev: vk.PhysicalDevice,
    allocator: Allocator,
    surface: vk.SurfaceKHR,
) !?DeviceCandidate {
    if (!try checkExtensionSupport(instance, pdev, allocator)) {
        return null;
    }

    if (!try checkSurfaceSupport(instance, pdev, surface)) {
        return null;
    }

    if (try allocateQueues(instance, pdev, allocator, surface)) |allocation| {
        const props = instance.getPhysicalDeviceProperties(pdev);
        return DeviceCandidate{
            .pdev = pdev,
            .props = props,
            .queues = allocation,
        };
    }

    return null;
}

fn allocateQueues(instance: Instance, pdev: vk.PhysicalDevice, allocator: Allocator, surface: vk.SurfaceKHR) !?QueueAllocation {
    const families = try instance.getPhysicalDeviceQueueFamilyPropertiesAlloc(pdev, allocator);
    defer allocator.free(families);

    var graphics_family: ?u32 = null;
    var present_family: ?u32 = null;

    for (families, 0..) |properties, i| {
        const family: u32 = @intCast(i);

        if (graphics_family == null and properties.queue_flags.graphics_bit) {
            graphics_family = family;
        }

        if (present_family == null and (try instance.getPhysicalDeviceSurfaceSupportKHR(pdev, family, surface)) == .true) {
            present_family = family;
        }
    }

    if (graphics_family != null and present_family != null) {
        return QueueAllocation{
            .graphics_family = graphics_family.?,
            .present_family = present_family.?,
        };
    }

    return null;
}

fn checkSurfaceSupport(instance: Instance, pdev: vk.PhysicalDevice, surface: vk.SurfaceKHR) !bool {
    var format_count: u32 = undefined;
    _ = try instance.getPhysicalDeviceSurfaceFormatsKHR(pdev, surface, &format_count, null);

    var present_mode_count: u32 = undefined;
    _ = try instance.getPhysicalDeviceSurfacePresentModesKHR(pdev, surface, &present_mode_count, null);

    return format_count > 0 and present_mode_count > 0;
}

fn checkExtensionSupport(
    instance: Instance,
    pdev: vk.PhysicalDevice,
    allocator: Allocator,
) !bool {
    const propsv = try instance.enumerateDeviceExtensionPropertiesAlloc(pdev, null, allocator);
    defer allocator.free(propsv);

    for (required_device_extensions) |ext| {
        for (propsv) |props| {
            if (std.mem.eql(u8, std.mem.span(ext), std.mem.sliceTo(&props.extension_name, 0))) {
                break;
            }
        } else {
            return false;
        }
    }

    return true;
}
