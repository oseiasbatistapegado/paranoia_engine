const Vertex = @import("renderer").backend.types.Vertex;

pub const vertices = [4]Vertex{
    .{ .pos = .{ -0.5, -0.5 }, .color = .{ 1, 1, 1 }, .uv = .{ 0.0, 0.0 } },
    .{ .pos = .{ 0.5, -0.5 }, .color = .{ 1, 1, 1 }, .uv = .{ 1.0, 0.0 } },
    .{ .pos = .{ -0.5, 0.5 }, .color = .{ 1, 1, 1 }, .uv = .{ 0.0, 1.0 } },
    .{ .pos = .{ 0.5, 0.5 }, .color = .{ 1, 1, 1 }, .uv = .{ 1.0, 1.0 } },
};

pub const index = [6]u16{ 0, 1, 3, 0, 3, 2 };
