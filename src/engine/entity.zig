const std = @import("std");
const zmath = @import("zmath");
const anim = @import("animation.zig");
const physic = @import("physics.zig");

pub const Entity = struct {
    physix: physic.Physics,
    animation: anim.AnimationComponent,

    cached_scale_w: f32,
    cached_scale_h: f32,

    texture_id: u32,
    config: *const anim.SpriteConfig,

    pub fn init(physix: physic.Physics, texture_id: u32, config: *const anim.SpriteConfig) Entity {
        const base_h: f32 = 300.0;

        const aspect: f32 = config.sprite_width / config.sprite_height;

        return .{
            .physix = physix,
            .animation = .{},
            .cached_scale_h = base_h,
            .cached_scale_w = base_h * aspect,
            .texture_id = texture_id,
            .config = config,
        };
    }

    pub fn update(self: *Entity, dt: f32, vw: f32, vh: f32, gravity: f32) void {
        self.physix.update(dt, gravity);

        self.animation.facing_left = if (self.physix.dx != 0) self.physix.dx < 0 else self.animation.facing_left;

        const next_state: anim.AnimState = if (self.physix.z > 0) .jump else if (@abs(self.physix.dx) > 0 or @abs(self.physix.dy) > 0) .walk else .idle;
        self.animation.setState(next_state);

        self.animation.update(dt, self.config);

        self.applyScreenLimits(vw, vh);
    }

    fn applyScreenLimits(self: *Entity, vw: f32, vh: f32) void {
        const limit_x = (vw / 2.0) - 50.0;
        const limit_y = (vh / 2.0) - 50.0;
        self.physix.x = zmath.clamp(self.physix.x, -limit_x, limit_x);
        self.physix.y = zmath.clamp(self.physix.y, -limit_y, limit_y);
    }

    pub fn getMatrix(self: Entity, inv_vh: f32) zmath.Mat {
        const scale = zmath.scaling(self.cached_scale_w, self.cached_scale_h, 1.0);

        const half_vh = (0.5 / inv_vh);
        const normalized_y = (self.physix.y + half_vh) * inv_vh;
        const depth = 0.9 + (normalized_y * -0.8);

        const visual_y = self.physix.y - self.physix.z;
        const translation = zmath.translation(self.physix.x, visual_y, depth);

        return zmath.mul(scale, translation);
    }
};
