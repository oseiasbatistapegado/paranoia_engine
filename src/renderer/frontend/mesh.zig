const backend = @import("renderer").backend;
const vk = @import("vulkan");
const std = @import("std");

pub const Mesh = struct {
    gc: *const backend.context.GraphicsContext,
    vertex_buffer: backend.types.Buffer,
    index_buffer: backend.types.Buffer,
    index_count: u32,

    pub fn init(
        gc: *const backend.context.GraphicsContext,
        staging: *backend.context.StagingContext,
        vertices: []const backend.types.Vertex,
        indices: []const u16,
    ) !Mesh {
        const v_buffer = try gc.createBufferDeferred(staging, backend.types.Vertex, vertices, .{ .vertex_buffer_bit = true });
        const i_buffer = try gc.createBufferDeferred(staging, u16, indices, .{ .index_buffer_bit = true });

        return Mesh{
            .gc = gc,
            .vertex_buffer = v_buffer,
            .index_buffer = i_buffer,
            .index_count = @intCast(indices.len),
        };
    }

    pub fn draw(self: Mesh, cmdbuf: vk.CommandBuffer) void {
        const offset = [_]vk.DeviceSize{0};

        self.gc.dev.cmdBindVertexBuffers(cmdbuf, 0, 1, @ptrCast(&self.vertex_buffer.handle), &offset);
        self.gc.dev.cmdBindIndexBuffer(cmdbuf, self.index_buffer.handle, 0, .uint16);
        self.gc.dev.cmdDrawIndexed(cmdbuf, self.index_count, 1, 0, 0, 0);
    }

    pub fn deinit(self: Mesh) void {
        self.vertex_buffer.deinit(self.gc.dev);
        self.index_buffer.deinit(self.gc.dev);
    }
};
