const engine = @import("engine");

pub fn update(
    comptime T: type, 
    registry: *T,
    move_speed: f32,
    jump_force: f32,
) void {
    if (comptime !(@hasField(T, "move_x") and @hasField(T, "move_y") and @hasField(T, "jump"))) return;

    for (0..registry.count) |i| {
        registry.dx.items[i] = registry.move_x.items[i] * move_speed;
        registry.dy.items[i] = registry.move_y.items[i] * move_speed;

        if (registry.jump.items[i] and registry.z.items[i] <= 0) {
            registry.dz.items[i] = jump_force;
        }
    }
}
