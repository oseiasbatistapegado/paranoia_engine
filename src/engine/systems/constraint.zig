const engine = @import("engine");
const zmath = @import("zmath");

pub fn apply_screen_limits(comptime T: type, registry: *T, vw: f32, vh: f32) void {
    const limit_x = (vw / 2.0) - 50.0;
    const limit_y = (vh / 2.0) - 50.0;

    for (0..registry.count) |i| {
        registry.x.items[i] = zmath.clamp(registry.x.items[i], -limit_x, limit_x);
        registry.y.items[i] = zmath.clamp(registry.y.items[i], -limit_y, limit_y);
    }
}
