const std = @import("std");

pub const AnimationState = enum {
    idle,
    walk,
    attack,
    hurt,
    death,
    jump,
};

pub const AnimationData = struct {
    row: u32,
    frame_start: u32 = 0,
    frame_count: u32,
    speed: f32,
    loop: bool = true,
};

pub const SpriteConfig = struct {
    texture_path: []const u8,
    sheet_width: f32,
    sheet_height: f32,
    sprite_width: f32,
    sprite_height: f32,

    animations: [std.enums.values(AnimationState).len]AnimationData,

    pub fn getAnim(self: SpriteConfig, state: AnimationState) AnimationData {
        return self.animations[@intFromEnum(state)];
    }
};
