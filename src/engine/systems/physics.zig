const std = @import("std");
const engine = @import("engine");

pub fn update(
    comptime T: type,
    registry: *T,
    dt: f32,
    gravity: f32,
) void {
    if (!@hasField(T, "move_x") or !@hasField(T, "move_y"))
        return;

    for (0..registry.count) |i| {
        registry.x.items[i] += registry.dx.items[i] * dt;
        registry.y.items[i] += registry.dy.items[i] * dt;

        if (registry.z.items[i] > 0 or registry.dz.items[i] > 0) {
            registry.dz.items[i] -= gravity * dt;
            registry.z.items[i] += registry.dz.items[i] * dt;
        }

        if (registry.z.items[i] < 0) {
            registry.z.items[i] = 0;
            registry.dz.items[i] = 0;
        }
    }
}
