const engine = @import("engine");
const std = @import("std");

pub const ORC_CONFIG = engine.resources.animation.SpriteConfig{
    .texture_path = "assets/textures/characters/orc/base/Orc.png",
    .sheet_width = 800.0,
    .sheet_height = 600.0,
    .sprite_width = 100.0,
    .sprite_height = 100.0,
    .animations = init: {
        var anims = [_]engine.resources.animation.AnimationData{undefined} ** std.enums.values(engine.resources.animation.AnimationState).len;
        anims[@intFromEnum(engine.resources.animation.AnimationState.idle)] = .{ .row = 0, .frame_count = 6, .speed = 8.0 };
        anims[@intFromEnum(engine.resources.animation.AnimationState.walk)] = .{ .row = 1, .frame_count = 8, .speed = 12.0 };
        anims[@intFromEnum(engine.resources.animation.AnimationState.attack)] = .{ .row = 2, .frame_count = 6, .speed = 15.0, .loop = false };
        anims[@intFromEnum(engine.resources.animation.AnimationState.hurt)] = .{ .row = 4, .frame_count = 4, .speed = 10.0, .loop = false };
        anims[@intFromEnum(engine.resources.animation.AnimationState.death)] = .{ .row = 5, .frame_count = 4, .speed = 5.0, .loop = false };
        anims[@intFromEnum(engine.resources.animation.AnimationState.jump)] = .{ .row = 2, .frame_count = 1, .speed = 1.0 };
        break :init anims;
    },
};

pub const SOLDIER_CONFIG = engine.resources.animation.SpriteConfig{
    .texture_path = "assets/textures/characters/soldier/base/Soldier.png",
    .sheet_width = 900.0,
    .sheet_height = 700.0,
    .sprite_width = 100.0,
    .sprite_height = 100.0,
    .animations = init: {
        var anims = [_]engine.resources.animation.AnimationData{undefined} ** std.enums.values(engine.resources.animation.AnimationState).len;
        anims[@intFromEnum(engine.resources.animation.AnimationState.idle)] = .{ .row = 0, .frame_count = 6, .speed = 8.0 };
        anims[@intFromEnum(engine.resources.animation.AnimationState.walk)] = .{ .row = 1, .frame_count = 8, .speed = 12.0 };
        anims[@intFromEnum(engine.resources.animation.AnimationState.attack)] = .{ .row = 2, .frame_count = 6, .speed = 15.0, .loop = false };
        anims[@intFromEnum(engine.resources.animation.AnimationState.hurt)] = .{ .row = 5, .frame_count = 4, .speed = 10.0, .loop = false };
        anims[@intFromEnum(engine.resources.animation.AnimationState.death)] = .{ .row = 6, .frame_count = 4, .speed = 5.0, .loop = false };
        anims[@intFromEnum(engine.resources.animation.AnimationState.jump)] = .{ .row = 2, .frame_count = 1, .speed = 1.0 };
        break :init anims;
    },
};
