const engine = @import("engine");

pub fn update(entities: []engine.ecs.entity.Entity) void {
    for (entities) |*entity| {
        const next_state: engine.components.animation.AnimationState = if (entity.physix.z > 0) .jump
            else if (@abs(entity.intent.move_x) > 0 or @abs(entity.intent.move_y) > 0) .walk
            else .idle;

        entity.animation.setState(next_state);

        if (entity.intent.move_x != 0)
            entity.animation.facing_left = entity.intent.move_x < 0;
    }
}
