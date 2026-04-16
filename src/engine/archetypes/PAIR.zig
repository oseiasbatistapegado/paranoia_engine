const std = @import("std");
const engine = @import("engine");

pub const PAIR = struct {
    allocator: std.mem.Allocator,

    // entity
    entity_id: std.ArrayList(u32),

    // physix component
    x: std.ArrayList(f32),
    y: std.ArrayList(f32),
    z: std.ArrayList(f32),
    dx: std.ArrayList(f32),
    dy: std.ArrayList(f32),
    dz: std.ArrayList(f32),
    friction: std.ArrayList(f32),

    // animation component
    state: std.ArrayList(engine.resources.animation.AnimationState),
    facing_left: std.ArrayList(bool),
    current_frame: std.ArrayList(u32),
    timer: std.ArrayList(f32),

    // intent component
    move_x: std.ArrayList(f32),
    move_y: std.ArrayList(f32),
    jump: std.ArrayList(bool),

    // renderer
    cached_scale_w: std.ArrayList(f32),
    cached_scale_h: std.ArrayList(f32),
    texture_id: std.ArrayList(u32),
    config: std.ArrayList(*const engine.resources.animation.SpriteConfig),

    count: usize,

    pub fn init(allocator: std.mem.Allocator) PAIR {
        var self: PAIR = undefined;
        self.allocator = allocator;
        self.count = 0;

        inline for (std.meta.fields(@TypeOf(self))) |field| {
            if (comptime std.meta.hasFn(field.type, "swapRemove"))
                @field(self, field.name) = .empty;
        }

        return self;
    }

    pub fn deinit(self: *PAIR) void {
        inline for (std.meta.fields(@TypeOf(self.*))) |field| {
            if (comptime std.meta.hasFn(field.type, "deinit"))
                @field(self, field.name).deinit(self.allocator);
        }
    }

    pub fn append(
        self: *PAIR,
        id: u32,
        config: *const engine.resources.animation.SpriteConfig,
        tex_id: u32,
        x: f32,
        y: f32,
    ) !usize {
        const base_h = 300.0;
        const aspect = config.sprite_width / config.sprite_height;

        try self.entity_id.append(self.allocator, id);

        // Physix
        try self.x.append(self.allocator, x);
        try self.y.append(self.allocator, y);
        try self.z.append(self.allocator, 0);
        try self.dx.append(self.allocator, 0);
        try self.dy.append(self.allocator, 0);
        try self.dz.append(self.allocator, 0);
        try self.friction.append(self.allocator, 0.1);

        // Animation
        try self.state.append(self.allocator, .idle);
        try self.facing_left.append(self.allocator, false);
        try self.current_frame.append(self.allocator, 0);
        try self.timer.append(self.allocator, 0);

        // Intent
        try self.move_x.append(self.allocator, 0);
        try self.move_y.append(self.allocator, 0);
        try self.jump.append(self.allocator, false);

        // Render
        try self.texture_id.append(self.allocator, tex_id);
        try self.config.append(self.allocator, config);
        try self.cached_scale_w.append(self.allocator, base_h * aspect);
        try self.cached_scale_h.append(self.allocator, base_h);

        const arch_idx = self.count;
        self.count += 1;

        return arch_idx;
    }

    pub fn swapRemove(self: *PAIR, index: u32) ?u32 {
        if (self.count == 0) return null;

        inline for (std.meta.fields(@TypeOf(self.*))) |field| {
            if (comptime std.meta.hasFn(field.type, "swapRemove"))
                _ = @field(self, field.name).swapRemove(index);
        }

        self.count -= 1;

        if (index < self.count)
            return self.entity_id.items[index];

        return null;
    }
};
