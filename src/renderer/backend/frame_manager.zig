const std = @import("std");

const GraphicsContext = @import("context.zig").GraphicsContext;
const Swapchain = @import("swapchain.zig").Swapchain;
const Allocator = std.mem.Allocator;
const vk = @import("vulkan");
const zmath = @import("zmath");
const types = @import("types.zig");
const frontend = @import("renderer").frontend;

pub const FrameManager = struct {
    gc: *const GraphicsContext,
    allocator: Allocator,
    pool: vk.CommandPool,
    render_pass: vk.RenderPass,
    pipeline: vk.Pipeline,
    pipeline_layout: vk.PipelineLayout,
    frame_buffers: []vk.Framebuffer,
    command_buffers: []vk.CommandBuffer,
    in_flight_fences: []vk.Fence,
    image_available_semaphores: []vk.Semaphore,
    render_finished_semaphores: []vk.Semaphore,

    pub fn init(
        gc: *const GraphicsContext,
        allocator: Allocator,
        swapchain: Swapchain,
        pipeline_layout: vk.PipelineLayout,
        pipeline: vk.Pipeline,
        render_pass: vk.RenderPass,
    ) !FrameManager {
        const pool = try gc.dev.createCommandPool(&.{
            .queue_family_index = gc.graphics_queue.family,
            .flags = .{ .reset_command_buffer_bit = true },
        }, null);

        var self = FrameManager{
            .gc = gc,
            .allocator = allocator,
            .pool = pool,
            .render_pass = render_pass,
            .pipeline = pipeline,
            .pipeline_layout = pipeline_layout,
            .frame_buffers = undefined,
            .command_buffers = undefined,
            .in_flight_fences = undefined,
            .image_available_semaphores = undefined,
            .render_finished_semaphores = undefined,
        };

        try self.create_resources(swapchain);

        return self;
    }

    pub fn beginCommandBuffer(self: *FrameManager, cmdbuf: vk.CommandBuffer) !void {
        try self.gc.dev.resetCommandBuffer(cmdbuf, .{});
        try self.gc.dev.beginCommandBuffer(cmdbuf, &.{
            .flags = .{ .one_time_submit_bit = true },
        });
    }

    pub fn endCommandBuffer(self: *FrameManager, cmdbuf: vk.CommandBuffer) !void {
        try self.gc.dev.endCommandBuffer(cmdbuf);
    }

    pub fn beginRenderPass(self: *FrameManager, cmdbuf: vk.CommandBuffer, framebuffer: vk.Framebuffer, extent: vk.Extent2D) void {
        const clears = [_]vk.ClearValue{
            .{ .color = .{ .float_32 = .{ 0, 0, 0, 1 } } },
            .{ .depth_stencil = .{ .depth = 1.0, .stencil = 0 } },
        };

        const viewport = vk.Viewport{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(extent.width),
            .height = @floatFromInt(extent.height),
            .min_depth = 0,
            .max_depth = 1,
        };

        const scissor = vk.Rect2D{
            .offset = .{ .x = 0, .y = 0 },
            .extent = extent,
        };

        self.gc.dev.cmdSetViewport(cmdbuf, 0, 1, @ptrCast(&viewport));
        self.gc.dev.cmdSetScissor(cmdbuf, 0, 1, @ptrCast(&scissor));

        self.gc.dev.cmdBeginRenderPass(cmdbuf, &.{
            .render_pass = self.render_pass,
            .framebuffer = framebuffer,
            .render_area = .{ .offset = .{ .x = 0, .y = 0 }, .extent = extent },
            .clear_value_count = clears.len,
            .p_clear_values = &clears,
        }, .@"inline");

        self.gc.dev.cmdBindPipeline(cmdbuf, .graphics, self.pipeline);
    }

    pub fn endRenderPass(self: *FrameManager, cmdbuf: vk.CommandBuffer) void {
        self.gc.dev.cmdEndRenderPass(cmdbuf);
    }

    pub fn refresh_resources(self: *FrameManager, swapchain: Swapchain) !void {
        try self.gc.dev.deviceWaitIdle();

        self.destroy_resources();

        try self.create_resources(swapchain);
    }

    pub fn create_resources(self: *FrameManager, swapchain: Swapchain) !void {
        const img_count = swapchain.swap_images.len;

        self.frame_buffers = try create_frame_buffers(self.gc, self.allocator, self.render_pass, swapchain);
        self.command_buffers = try self.allocator.alloc(vk.CommandBuffer, img_count);
        self.in_flight_fences = try self.allocator.alloc(vk.Fence, img_count);
        self.image_available_semaphores = try self.allocator.alloc(vk.Semaphore, img_count);
        self.render_finished_semaphores = try self.allocator.alloc(vk.Semaphore, img_count);

        try self.gc.dev.allocateCommandBuffers(&.{
            .command_pool = self.pool,
            .level = .primary,
            .command_buffer_count = @intCast(img_count),
        }, self.command_buffers.ptr);

        for (0..img_count) |i| {
            self.in_flight_fences[i] = try self.gc.dev.createFence(&.{
                .flags = .{ .signaled_bit = true },
            }, null);

            self.image_available_semaphores[i] = try self.gc.dev.createSemaphore(&.{}, null);
            self.render_finished_semaphores[i] = try self.gc.dev.createSemaphore(&.{}, null);
        }
    }

    pub fn destroy_resources(self: *FrameManager) void {
        for (self.in_flight_fences) |f| self.gc.dev.destroyFence(f, null);
        for (self.image_available_semaphores) |s| self.gc.dev.destroySemaphore(s, null);
        for (self.render_finished_semaphores) |s| self.gc.dev.destroySemaphore(s, null);
        for (self.frame_buffers) |fb| self.gc.dev.destroyFramebuffer(fb, null);

        if (self.command_buffers.len > 0) {
            self.gc.dev.freeCommandBuffers(self.pool, @intCast(self.command_buffers.len), self.command_buffers.ptr);
        }

        self.allocator.free(self.frame_buffers);
        self.allocator.free(self.command_buffers);
        self.allocator.free(self.in_flight_fences);
        self.allocator.free(self.image_available_semaphores);
        self.allocator.free(self.render_finished_semaphores);

        self.in_flight_fences = &[_]vk.Fence{};
    }

    pub fn beginFrame(self: *FrameManager, swapchain: Swapchain, frame_idx: u32, images_in_flight: []vk.Fence) !u32 {
        _ = try self.gc.dev.waitForFences(1, @ptrCast(&self.in_flight_fences[frame_idx]), .true, std.math.maxInt(u64));

        const result = try self.gc.dev.acquireNextImageKHR(
            swapchain.handle,
            std.math.maxInt(u64),
            self.image_available_semaphores[frame_idx],
            .null_handle,
        );

        if (images_in_flight[result.image_index] != .null_handle) {
            _ = try self.gc.dev.waitForFences(1, @ptrCast(&images_in_flight[result.image_index]), .true, std.math.maxInt(u64));
        }

        images_in_flight[result.image_index] = self.in_flight_fences[frame_idx];

        try self.gc.dev.resetFences(1, @ptrCast(&self.in_flight_fences[frame_idx]));
        return result.image_index;
    }

    pub fn endFrame(self: *FrameManager, swapchain: Swapchain, frame_idx: u32, img_idx: u32) !void {
        const wait_stage = [_]vk.PipelineStageFlags{.{ .color_attachment_output_bit = true, .early_fragment_tests_bit = true }};

        try self.gc.dev.queueSubmit(self.gc.graphics_queue.handle, 1, @ptrCast(&vk.SubmitInfo{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&self.image_available_semaphores[frame_idx]),
            .p_wait_dst_stage_mask = &wait_stage,
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&self.command_buffers[img_idx]),
            .signal_semaphore_count = 1,

            .p_signal_semaphores = @ptrCast(&self.render_finished_semaphores[img_idx]),
        }), self.in_flight_fences[frame_idx]);

        _ = try self.gc.dev.queuePresentKHR(self.gc.present_queue.handle, &.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&self.render_finished_semaphores[img_idx]),
            .swapchain_count = 1,
            .p_swapchains = @ptrCast(&swapchain.handle),
            .p_image_indices = @ptrCast(&img_idx),
        });
    }
    pub fn deinit(self: *FrameManager) void {
        self.gc.dev.deviceWaitIdle() catch {};
        self.destroy_resources();
        self.gc.dev.destroyCommandPool(self.pool, null);
    }
};

fn create_frame_buffers(gc: *const GraphicsContext, allocator: Allocator, render_pass: vk.RenderPass, swapchain: Swapchain) ![]vk.Framebuffer {
    const framebuffers = try allocator.alloc(vk.Framebuffer, swapchain.swap_images.len);
    errdefer allocator.free(framebuffers);

    for (swapchain.swap_images, 0..) |image, i| {
        const attachments = [_]vk.ImageView{ image.view, swapchain.depth_image_view };

        framebuffers[i] = try gc.dev.createFramebuffer(&.{
            .render_pass = render_pass,
            .attachment_count = attachments.len,
            .p_attachments = &attachments,
            .width = swapchain.extent.width,
            .height = swapchain.extent.height,
            .layers = 1,
        }, null);
    }

    return framebuffers;
}

fn destroy_frame_buffers(gc: *const GraphicsContext, allocator: Allocator, framebuffers: []const vk.Framebuffer) void {
    for (framebuffers) |fb| gc.dev.destroyFramebuffer(fb, null);
    allocator.free(framebuffers);
}
