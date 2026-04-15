const std = @import("std");
const engine = @import("engine");
const renderer = @import("renderer");

pub const Registry = struct {
    PAR: engine.archetypes.PAR,
    PAIR: engine.archetypes.PAIR,

    pub fn init(allocator: std.mem.Allocator) Registry {
        return .{
            .PAR = engine.archetypes.PAR.init(allocator),
            .PAIR = engine.archetypes.PAIR.init(allocator),
        };
    }

    pub fn deinit(self: *Registry) void {
        inline for (std.meta.fields(Registry)) |field| {
            const archetype = &@field(self, field.name);
            archetype.deinit();
        }
    }

    pub fn spawn(
        self: *Registry,
        comptime T: []const u8,
        config: *const engine.resources.animation.SpriteConfig,
        tex_id: u32,
        x: f32,
        y: f32,
    ) !usize {
        return try @field(self, T).append(config, tex_id, x, y);
    }

    pub fn updateAll(self: *Registry, dt: f32, vw: f32, vh: f32, move_speed: f32, jump_force: f32, gravity: f32) void { 
        inline for (std.meta.fields(Registry)) |field| {
            const archetype = &@field(self, field.name);
            const T = field.type;

            engine.systems.movement.update(T, archetype, move_speed, jump_force);
            engine.systems.physix.update(T, archetype, dt, gravity);
            engine.systems.animator.update(T, archetype);
            engine.systems.animation.update(T, archetype, dt);
            engine.systems.constraint.apply_screen_limits(T, archetype, vw, vh);
        }
    }

    pub fn drawAll(self: *Registry, r2d: *renderer.frontend.renderer2d.Renderer2D, inv_vh: f32) void {
        inline for (std.meta.fields(Registry)) |field| {
            const archetype = &@field(self, field.name);
            const T = field.type;
            renderer.systems.render.update(T, archetype, r2d, inv_vh);
        }
    }
};
