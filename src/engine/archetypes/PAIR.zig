const std = @import("std");
const engine = @import("engine");

pub const PAIR = struct {
    allocator: std.mem.Allocator,

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
        return .{
            .allocator = allocator,

            .x = .empty,
            .y = .empty,
            .z = .empty,
            .dx = .empty,
            .dy = .empty,
            .dz = .empty,
            .friction = .empty,

            .state = .empty,
            .facing_left = .empty,
            .current_frame = .empty,
            .timer = .empty,

            .move_x = .empty,
            .move_y = .empty,
            .jump = .empty,

            .cached_scale_w = .empty,
            .cached_scale_h = .empty,
            .texture_id = .empty,
            .config = .empty,

            .count = 0,
        };
    }

    pub fn deinit(self: *PAIR) void {
        self.x.deinit(self.allocator);
        self.y.deinit(self.allocator);
        self.z.deinit(self.allocator);
        self.dx.deinit(self.allocator);
        self.dy.deinit(self.allocator);
        self.dz.deinit(self.allocator);
        self.friction.deinit(self.allocator);

        self.state.deinit(self.allocator);
        self.facing_left.deinit(self.allocator);
        self.current_frame.deinit(self.allocator);
        self.timer.deinit(self.allocator);

        self.move_x.deinit(self.allocator);
        self.move_y.deinit(self.allocator);
        self.jump.deinit(self.allocator);

        self.cached_scale_w.deinit(self.allocator);
        self.cached_scale_h.deinit(self.allocator);
        self.texture_id.deinit(self.allocator);
        self.config.deinit(self.allocator);
    }

    pub fn append(
        self: *PAIR,
        config: *const engine.resources.animation.SpriteConfig,
        tex_id: u32,
        x: f32,
        y: f32,
    ) !usize {
        const base_h = 300.0;
        const aspect = config.sprite_width / config.sprite_height;

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

        const id = self.count;
        self.count += 1;

        return id;
    }
};
