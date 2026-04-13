const engine = @import("engine");
const zmath = @import("zmath");

pub fn apply_screen_limits(entities: []engine.ecs.entity.Entity, vw: f32, vh: f32) void {
    const limit_x = (vw / 2.0) - 50.0;
    const limit_y = (vh / 2.0) - 50.0;

    for (entities) |*entity| {
        entity.physix.x = zmath.clamp(entity.physix.x, -limit_x, limit_x);
        entity.physix.y = zmath.clamp(entity.physix.y, -limit_y, limit_y);
    }
}
