const engine = @import("engine");

pub fn update(entities: []engine.ecs.entity.Entity, dt: f32) void {
    for (entities) |*entity| {
        const current_anim = entity.config.getAnim(entity.animation.state);
        entity.animation.timer += dt;

        if (entity.animation.timer > (1.0 / current_anim.speed)) {
            entity.animation.timer = 0;
            entity.animation.current_frame += 1;

            if (entity.animation.current_frame >= current_anim.frame_count) {
                entity.animation.current_frame = if (current_anim.loop) 0 else current_anim.frame_count - 1;
            }
        }
    }
}
