const std = @import("std");
const engine = @import("engine");
const renderer = @import("renderer");

pub const Registry = struct {
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
    state: std.ArrayList(engine.components.animation.AnimationState),
    facing_left: std.ArrayList(bool),
    current_frame: std.ArrayList(u32),
    timer: std.ArrayList(f32),

    // intent component
    move_x: std.ArrayList(f32),
    move_y: std.ArrayList(f32),
    jump: std.ArrayList(bool),

    cached_scale_w: std.ArrayList(f32),
    cached_scale_h: std.ArrayList(f32),

    texture_id: std.ArrayList(u32),
    config: std.ArrayList(*const engine.components.animation.SpriteConfig),

    count: usize = 0,

    pub fn init(allocator: std.mem.Allocator) Registry {
        return .{
            .allocator = allocator,
            // physix component
            .x = .empty,
            .y = .empty,
            .z = .empty,
            .dx = .empty,
            .dy = .empty,
            .dz = .empty,
            .friction = .empty,

            // animation component
            .state = .empty,
            .facing_left = .empty,
            .current_frame = .empty,
            .timer = .empty,

            // intent component
            .move_x = .empty,
            .move_y = .empty,
            .jump = .empty,

            .cached_scale_w = .empty,
            .cached_scale_h = .empty,
            .texture_id = .empty,
            .config = .empty,
        };
    }

    pub fn deinit(self: *Registry) void {
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

    pub fn spawn(
        self: *Registry,
        config: *const engine.components.animation.SpriteConfig,
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

    pub fn updateAll(self: *Registry, dt: f32, vw: f32, vh: f32, move_speed: f32, jump_force: f32, gravity: f32) void {
        engine.system.movement.update(
            self.move_x.items,
            self.move_y.items,
            self.jump.items,
            self.dx.items,
            self.dy.items,
            self.dz.items,
            self.z.items,
            self.count,
            move_speed,
            jump_force,
        );

        engine.system.physix.update(
            self.x.items,
            self.y.items,
            self.z.items,
            self.dx.items,
            self.dy.items,
            self.dz.items,
            self.count,
            dt,
            gravity,
        );

        engine.system.gameplay.update(
            self.dx.items,
            self.dy.items,
            self.z.items,
            self.state.items,
            self.facing_left.items,
            self.current_frame.items,
            self.timer.items,
            self.count,
        );

        engine.system.animation.update(
            self.state.items,
            self.current_frame.items,
            self.timer.items,
            self.config.items,
            self.count,
            dt,
        );

        engine.system.constraint.apply_screen_limits(
            self.x.items,
            self.y.items,
            self.count,
            vw,
            vh,
        );
    }

    pub fn drawAll(self: *Registry, r2d: *renderer.frontend.renderer2d.Renderer2D, inv_vh: f32) void {
        for (0..self.count) |i| {
            r2d.drawEntity(
                self.x.items[i],
                self.y.items[i],
                self.z.items[i],

                self.state.items[i],
                self.facing_left.items[i],
                self.current_frame.items[i],

                self.texture_id.items[i],
                self.config.items[i],

                self.cached_scale_w.items[i],
                self.cached_scale_h.items[i],

                inv_vh,
            );
        }
    }
};
