const std = @import("std");
const vk = @import("vulkan");
const zstbi = @import("zstbi");
const context = @import("context.zig");
const types = @import("types.zig");

pub const Texture = struct {
    image: vk.Image,
    memory: vk.DeviceMemory,
    view: vk.ImageView,
    sampler: vk.Sampler,
    width: u32,
    height: u32,

    pub fn initFromMemory(
        gc: *const context.GraphicsContext,
        data: []const u8,
        width: u32,
        height: u32,
    ) !Texture {
        const image_size = @as(vk.DeviceSize, width * height * 4);

        const staging = try gc.createBuffer(
            image_size,
            .{ .transfer_src_bit = true },
            .{ .host_visible_bit = true, .host_coherent_bit = true },
        );
        defer staging.deinit(gc.dev);

        const ptr = try gc.dev.mapMemory(staging.memory, 0, image_size, .{});
        @memcpy(@as([*]u8, @ptrCast(ptr)), data);
        gc.dev.unmapMemory(staging.memory);

        const format = vk.Format.r8g8b8a8_unorm;
        const image_info = vk.ImageCreateInfo{
            .image_type = .e2d,
            .extent = .{ .width = width, .height = height, .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .format = format,
            .tiling = .optimal,
            .initial_layout = .undefined,
            .usage = .{ .transfer_dst_bit = true, .sampled_bit = true },
            .sharing_mode = .exclusive,
            .samples = .{ .@"1_bit" = true },
        };

        const image = try gc.dev.createImage(&image_info, null);
        const mem_reqs = gc.dev.getImageMemoryRequirements(image);
        const memory = try gc.allocMemory(mem_reqs, .{ .device_local_bit = true });
        try gc.dev.bindImageMemory(image, memory, 0);

        const view = try gc.dev.createImageView(&.{
            .image = image,
            .view_type = .e2d,
            .format = format,
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        }, null);

        const sampler = try gc.dev.createSampler(&.{
            .mag_filter = .nearest,
            .min_filter = .nearest,
            .address_mode_u = .clamp_to_edge,
            .address_mode_v = .clamp_to_edge,
            .mipmap_mode = .nearest,
            .anisotropy_enable = .false,
            .compare_enable = .false,
            .unnormalized_coordinates = .false,
        }, null);

        return .{
            .image = image,
            .memory = memory,
            .view = view,
            .sampler = sampler,
            .width = width,
            .height = height,
        };
    }

    pub fn transitionImageLayout(
        gc: *const context.GraphicsContext,
        cmd: vk.CommandBuffer,
        image: vk.Image,
        old_layout: vk.ImageLayout,
        new_layout: vk.ImageLayout,
    ) !void {
        var barrier = vk.ImageMemoryBarrier{
            .old_layout = old_layout,
            .new_layout = new_layout,
            .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .image = image,
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .src_access_mask = .{},
            .dst_access_mask = .{},
        };

        var source_stage: vk.PipelineStageFlags = .{};
        var destination_stage: vk.PipelineStageFlags = .{};

        if (old_layout == .undefined and new_layout == .transfer_dst_optimal) {
            barrier.src_access_mask = .{};
            barrier.dst_access_mask = .{ .transfer_write_bit = true };
            source_stage = .{ .top_of_pipe_bit = true };
            destination_stage = .{ .transfer_bit = true };
        } else if (old_layout == .transfer_dst_optimal and new_layout == .shader_read_only_optimal) {
            barrier.src_access_mask = .{ .transfer_write_bit = true };
            barrier.dst_access_mask = .{ .shader_read_bit = true };
            source_stage = .{ .transfer_bit = true };
            destination_stage = .{ .fragment_shader_bit = true };
        } else {
            return error.UnsupportedLayoutTransition;
        }

        gc.dev.cmdPipelineBarrier(
            cmd,
            source_stage,
            destination_stage,
            .{},
            null,
            null,
            &[_]vk.ImageMemoryBarrier{barrier},
        );
    }

    pub fn copyBufferToImage(
        gc: *const context.GraphicsContext,
        cmd: vk.CommandBuffer,
        buffer: vk.Buffer,
        image: vk.Image,
        width: u32,
        height: u32,
    ) void {
        const region = vk.BufferImageCopy{
            .buffer_offset = 0,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_subresource = .{
                .aspect_mask = .{ .color_bit = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .image_offset = .{ .x = 0, .y = 0, .z = 0 },
            .image_extent = .{ .width = width, .height = height, .depth = 1 },
        };

        gc.dev.cmdCopyBufferToImage(
            cmd,
            buffer,
            image,
            .transfer_dst_optimal,
            &[_]vk.BufferImageCopy{region},
        );

        // gc.dev.cmdCopyBufferToImage(
        //     cmd,
        //     buffer,
        //     image,
        //     .transfer_dst_optimal,
        //     1,
        //     @ptrCast(&region),
        // );
    }

    pub fn deinit(self: Texture, dev: vk.DeviceProxy) void {
        dev.destroySampler(self.sampler, null);
        dev.destroyImageView(self.view, null);
        dev.destroyImage(self.image, null);
        dev.freeMemory(self.memory, null);
    }
};
