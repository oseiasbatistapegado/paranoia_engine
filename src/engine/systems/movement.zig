const engine = @import("engine");

pub fn update(entities: []engine.ecs.entity.Entity, move_speed: f32, jump_force: f32) void {
    for (entities) |*entity| {
        entity.physix.dx = entity.intent.move_x * move_speed;
        entity.physix.dy = entity.intent.move_y * move_speed;

        if (entity.intent.jump and entity.physix.z <= 0) {
            entity.physix.dz = jump_force;
        }
    }
}
