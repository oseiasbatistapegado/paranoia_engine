const engine = @import("engine");
const zmath = @import("zmath");

pub fn apply_screen_limits(
    x: []f32,
    y: []f32,
    count: u64,
    vw: f32,
    vh: f32,
) void {
    const limit_x = (vw / 2.0) - 50.0;
    const limit_y = (vh / 2.0) - 50.0;

    for (0..count) |i| {
        x[i] = zmath.clamp(x[i], -limit_x, limit_x);
        y[i] = zmath.clamp(y[i], -limit_y, limit_y);
    }
}
