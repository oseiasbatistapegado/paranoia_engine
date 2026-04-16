const vk = @import("vulkan");
const zmath = @import("zmath");

pub const Buffer = struct {
    handle: vk.Buffer,
    memory: vk.DeviceMemory,
    size: vk.DeviceSize,

    pub fn deinit(self: Buffer, dev: vk.DeviceProxy) void {
        dev.destroyBuffer(self.handle, null);
        dev.freeMemory(self.memory, null);
    }
};

pub const Vertex = struct {
    pos: [2]f32,
    color: [3]f32,
    uv: [2]f32,

    pub const binding_description = vk.VertexInputBindingDescription{
        .binding = 0,
        .stride = @sizeOf(Vertex),
        .input_rate = .vertex,
    };

    pub const attribute_descriptions = [_]vk.VertexInputAttributeDescription{
        .{ .binding = 0, .location = 0, .format = .r32g32_sfloat, .offset = @offsetOf(Vertex, "pos") },

        .{ .binding = 0, .location = 1, .format = .r32g32_sfloat, .offset = @offsetOf(Vertex, "uv") },
    };
};

pub const InstanceData = struct {
    pos: [3]f32,        // x, visual_y, depth
    scale: [2]f32,      // sw, sh
    uv_offset: [2]f32,
    uv_scale: [2]f32,
    texture_id: u32,

    pub const binding_description = vk.VertexInputBindingDescription{
        .binding = 1,
        .stride = @sizeOf(InstanceData),
        .input_rate = .instance,
    };

    pub const attribute_descriptions = [_]vk.VertexInputAttributeDescription{
        .{ .binding = 1, .location = 2, .format = .r32g32b32_sfloat, .offset = @offsetOf(InstanceData, "pos") },
        .{ .binding = 1, .location = 3, .format = .r32g32_sfloat, .offset = @offsetOf(InstanceData, "scale") },
        .{ .binding = 1, .location = 4, .format = .r32g32_sfloat, .offset = @offsetOf(InstanceData, "uv_offset") },
        .{ .binding = 1, .location = 5, .format = .r32g32_sfloat, .offset = @offsetOf(InstanceData, "uv_scale") },
        .{ .binding = 1, .location = 6, .format = .r32_uint, .offset = @offsetOf(InstanceData, "texture_id") },
    };
};

pub const MeshPushConstants = struct {
    model: zmath.Mat,
};
