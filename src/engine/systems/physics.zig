const std = @import("std");
const engine = @import("engine");

pub fn update(entites: []engine.ecs.entity.Entity, dt: f32, gravity: f32) void {
    for (entites) |*entity| {
        entity.physix.x += entity.physix.dx * dt;
        entity.physix.y += entity.physix.dy * dt;

        if (entity.physix.z > 0 or entity.physix.dz > 0) {
            entity.physix.dz -= gravity * dt;
            entity.physix.z += entity.physix.dz * dt;
        }

        if (entity.physix.z < 0) {
            entity.physix.z = 0;
            entity.physix.dz = 0;
        }
    }
}
