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

pub const ORC_CONFIG = SpriteConfig{
    .texture_path = "assets/textures/characters/orc/base/Orc.png",
    .sheet_width = 800.0,
    .sheet_height = 600.0,
    .sprite_width = 100.0,
    .sprite_height = 100.0,
    .animations = init: {
        var anims = [_]AnimationData{undefined} ** std.enums.values(AnimationState).len;
        anims[@intFromEnum(AnimationState.idle)] = .{ .row = 0, .frame_count = 6, .speed = 8.0 };
        anims[@intFromEnum(AnimationState.walk)] = .{ .row = 1, .frame_count = 8, .speed = 12.0 };
        anims[@intFromEnum(AnimationState.attack)] = .{ .row = 2, .frame_count = 6, .speed = 15.0, .loop = false };
        anims[@intFromEnum(AnimationState.hurt)] = .{ .row = 4, .frame_count = 4, .speed = 10.0, .loop = false };
        anims[@intFromEnum(AnimationState.death)] = .{ .row = 5, .frame_count = 4, .speed = 5.0, .loop = false };
        anims[@intFromEnum(AnimationState.jump)] = .{ .row = 2, .frame_count = 1, .speed = 1.0 };
        break :init anims;
    },
};

pub const SOLDIER_CONFIG = SpriteConfig{
    .texture_path = "assets/textures/characters/soldier/base/Soldier.png",
    .sheet_width = 900.0,
    .sheet_height = 700.0,
    .sprite_width = 100.0,
    .sprite_height = 100.0,
    .animations = init: {
        var anims = [_]AnimationData{undefined} ** std.enums.values(AnimationState).len;
        anims[@intFromEnum(AnimationState.idle)] = .{ .row = 0, .frame_count = 6, .speed = 8.0 };
        anims[@intFromEnum(AnimationState.walk)] = .{ .row = 1, .frame_count = 8, .speed = 12.0 };
        anims[@intFromEnum(AnimationState.attack)] = .{ .row = 2, .frame_count = 6, .speed = 15.0, .loop = false };
        anims[@intFromEnum(AnimationState.hurt)] = .{ .row = 5, .frame_count = 4, .speed = 10.0, .loop = false };
        anims[@intFromEnum(AnimationState.death)] = .{ .row = 6, .frame_count = 4, .speed = 5.0, .loop = false };
        anims[@intFromEnum(AnimationState.jump)] = .{ .row = 2, .frame_count = 1, .speed = 1.0 };
        break :init anims;
    },
};

pub const AnimationComponent = struct {
    state: AnimationState = .idle,
    facing_left: bool = false,
    current_frame: u32 = 0,
    timer: f32 = 0.0,

    pub fn setState(self: *AnimationComponent, new_state: AnimationState) void {
        if (self.state != new_state) {
            self.state = new_state;
            self.current_frame = 0;
            self.timer = 0;
        }
    }
};
