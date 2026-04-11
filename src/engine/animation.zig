const std = @import("std");

pub const AnimState = enum {
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

    animations: [std.enums.values(AnimState).len]AnimationData,

    pub fn getAnim(self: SpriteConfig, state: AnimState) AnimationData {
        return self.animations[@intFromEnum(state)];
    }
};

pub const ORC_CONFIG = SpriteConfig{
    .texture_path = "assets/textures/characters/orc/Orc/Orc.png",
    .sheet_width = 800.0,
    .sheet_height = 600.0,
    .sprite_width = 100.0,
    .sprite_height = 100.0,
    .animations = init: {
        var anims = [_]AnimationData{undefined} ** std.enums.values(AnimState).len;
        anims[@intFromEnum(AnimState.idle)] = .{ .row = 0, .frame_count = 6, .speed = 8.0 };
        anims[@intFromEnum(AnimState.walk)] = .{ .row = 1, .frame_count = 8, .speed = 12.0 };
        anims[@intFromEnum(AnimState.attack)] = .{ .row = 2, .frame_count = 6, .speed = 15.0, .loop = false };
        anims[@intFromEnum(AnimState.hurt)] = .{ .row = 4, .frame_count = 4, .speed = 10.0, .loop = false };
        anims[@intFromEnum(AnimState.death)] = .{ .row = 5, .frame_count = 4, .speed = 5.0, .loop = false };
        anims[@intFromEnum(AnimState.jump)] = .{ .row = 2, .frame_count = 1, .speed = 1.0 };
        break :init anims;
    },
};

pub const SOLDIER_CONFIG = SpriteConfig{
    .texture_path = "assets/textures/characters/soldier/Soldier/Soldier.png",
    .sheet_width = 900.0,
    .sheet_height = 700.0,
    .sprite_width = 100.0,
    .sprite_height = 100.0,
    .animations = init: {
        var anims = [_]AnimationData{undefined} ** std.enums.values(AnimState).len;
        anims[@intFromEnum(AnimState.idle)] = .{ .row = 0, .frame_count = 6, .speed = 8.0 };
        anims[@intFromEnum(AnimState.walk)] = .{ .row = 1, .frame_count = 8, .speed = 12.0 };
        anims[@intFromEnum(AnimState.attack)] = .{ .row = 2, .frame_count = 6, .speed = 15.0, .loop = false };
        anims[@intFromEnum(AnimState.hurt)] = .{ .row = 5, .frame_count = 4, .speed = 10.0, .loop = false };
        anims[@intFromEnum(AnimState.death)] = .{ .row = 6, .frame_count = 4, .speed = 5.0, .loop = false };
        anims[@intFromEnum(AnimState.jump)] = .{ .row = 2, .frame_count = 1, .speed = 1.0 };
        break :init anims;
    },
};

pub const AnimationComponent = struct {
    state: AnimState = .idle,
    facing_left: bool = false,
    current_frame: u32 = 0,
    timer: f32 = 0.0,

    pub fn update(self: *AnimationComponent, dt: f32, config: *const SpriteConfig) void {
        const current_anim = config.getAnim(self.state);
        self.timer += dt;

        if (self.timer > (1.0 / current_anim.speed)) {
            self.timer = 0;
            self.current_frame += 1;
            if (self.current_frame >= current_anim.frame_count) {
                self.current_frame = if (current_anim.loop) 0 else current_anim.frame_count - 1;
            }
        }
    }

    pub fn setState(self: *AnimationComponent, new_state: AnimState) void {
        if (self.state != new_state) {
            self.state = new_state;
            self.current_frame = 0;
            self.timer = 0;
        }
    }
};
