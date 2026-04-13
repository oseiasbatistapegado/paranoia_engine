const std = @import("std");
const engine = @import("engine");
const renderer = @import("renderer");

pub const EntityManager = struct {
    entities: std.ArrayList(engine.ecs.entity.Entity),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) EntityManager {
        return .{
            .entities = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *EntityManager) void {
        self.entities.deinit(self.allocator);
    }

    pub fn spawn(self: *EntityManager, config: *const engine.components.animation.SpriteConfig, tex_id: u32, x: f32, y: f32) !usize {
        const new_entity = engine.ecs.entity.Entity.init(
            .{ .x = x, .y = y },
            tex_id,
            config,
        );
        try self.entities.append(self.allocator, new_entity);

        return self.entities.items.len - 1;
    }

    pub fn updateAll(self: *EntityManager, dt: f32, vw: f32, vh: f32, move_speed: f32, jump_force: f32, gravity: f32) void {
        const entities = self.entities.items;

        engine.system.movement.update(entities, move_speed, jump_force);
        engine.system.physix.update(entities, dt, gravity);
        engine.system.gameplay.update(entities);
        engine.system.animation.update(entities, dt);
        engine.system.constraint.apply_screen_limits(entities, vw, vh);
    }

    pub fn drawAll(self: *EntityManager, r2d: *renderer.frontend.renderer2d.Renderer2D, vh: f32) void {
        for (self.entities.items) |ent| {
            r2d.drawEntity(ent, vh);
        }
    }
};
