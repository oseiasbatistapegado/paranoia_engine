const engine = @import("engine");
const zmath = @import("zmath");
const std = @import("std");

pub const Entity = struct {
    physix: engine.components.physix.PhysixComponent,
    animation: engine.components.animation.AnimationComponent,
    intent: engine.components.movement.MovementComponent,

    cached_scale_w: f32,
    cached_scale_h: f32,

    texture_id: u32,
    config: *const engine.components.animation.SpriteConfig,

    pub fn init(physix: engine.components.physix.PhysixComponent, texture_id: u32, config: *const engine.components.animation.SpriteConfig) Entity {
        const base_h: f32 = 300.0;

        const aspect: f32 = config.sprite_width / config.sprite_height;

        return .{
            .physix = physix,
            .animation = .{},
            .intent = .{},
            .cached_scale_h = base_h,
            .cached_scale_w = base_h * aspect,
            .texture_id = texture_id,
            .config = config,
        };
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
