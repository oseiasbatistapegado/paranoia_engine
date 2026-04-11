const std = @import("std");
const entity = @import("entity.zig");
const animation = @import("animation.zig");
const renderer = @import("renderer");

pub const EntityManager = struct {
    entities: std.ArrayList(entity.Entity),
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

    pub fn spawn(self: *EntityManager, config: *const animation.SpriteConfig, tex_id: u32, x: f32, y: f32) !void {
        const new_entity = entity.Entity.init(
            .{ .x = x, .y = y },
            tex_id,
            config,
        );
        try self.entities.append(self.allocator, new_entity);
    }

    pub fn updateAll(self: *EntityManager, dt: f32, vw: f32, vh: f32, gravity: f32) void {
        for (self.entities.items) |*ent| {
            ent.update(dt, vw, vh, gravity);
        }
    }

    pub fn drawAll(self: *EntityManager, r2d: *renderer.frontend.renderer2d.Renderer2D, vh: f32) void {
        for (self.entities.items) |ent| {
            r2d.drawEntity(ent, vh);
        }
    }
};
