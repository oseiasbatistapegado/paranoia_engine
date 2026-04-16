const std = @import("std");
const engine = @import("engine");
const renderer = @import("renderer");

pub const  EntityHandle = struct {
    id: u32,
    gen: u32,
};

pub const Registry = struct {
    allocator: std.mem.Allocator,

    PAR: engine.archetypes.PAR,
    PAIR: engine.archetypes.PAIR,

    // locations
    archetype_ids: std.ArrayList(u32),
    indices: std.ArrayList(u32),
    generations: std.ArrayList(u32),

    // entities
    entity_ids: std.ArrayList(u32),
    entity_gen: std.ArrayList(u32),

    // indices controller
    free_indices: std.ArrayList(u32),

    pub fn init(allocator: std.mem.Allocator) Registry {
        return .{
            .allocator = allocator,
            .PAR = engine.archetypes.PAR.init(allocator),
            .PAIR = engine.archetypes.PAIR.init(allocator),
            .archetype_ids = .empty,
            .indices = .empty,
            .generations = .empty,
            .entity_ids = .empty,
            .entity_gen = .empty,
            .free_indices = .empty,
        };
    }

    pub fn deinit(self: *Registry) void {
        self.PAIR.deinit();
        self.PAR.deinit();
        self.archetype_ids.deinit(self.allocator);
        self.indices.deinit(self.allocator);
        self.generations.deinit(self.allocator);
        self.entity_ids.deinit(self.allocator);
        self.entity_gen.deinit(self.allocator);
        self.free_indices.deinit(self.allocator);
    }

    pub fn spawn(
        self: *Registry,
        comptime archetype: []const u8,
        config: *const engine.resources.animation.SpriteConfig,
        tex_id: u32,
        x: f32,
        y: f32,
    ) !EntityHandle {
        var id: u32 = undefined;
        var gen: u32 = 0;

        if (self.free_indices.items.len > 0) {
            id = self.free_indices.pop().?;
            gen = self.entity_gen.items[id];
        } else {
            id = @intCast(self.entity_gen.items.len);
            try self.entity_gen.append(self.allocator, 0);
            try self.archetype_ids.append(self.allocator, 0);
            try self.indices.append(self.allocator, 0);
            gen = 0;
        }

        const arch_idx = try @field(self, archetype).append(id, config, tex_id, x, y);

        const arch_id: u32 = if (std.mem.eql(u8, archetype, "PAR")) 0 else 1;
        self.archetype_ids.items[id] = arch_id;
        self.indices.items[id] = @intCast(arch_idx);

        return .{ .id = id, .gen = gen };
    }

    pub fn destroy(self: *Registry, handle: EntityHandle) void {
        if (handle.id >= self.entity_gen.items.len) return;
        if (self.entity_gen.items[handle.id] != handle.gen) return;

        const arch_id = self.archetype_ids.items[handle.id];
        const arch_idx = self.indices.items[handle.id];

        const moved_id: u32 = if (arch_id == 0) self.PAR.swapRemove(arch_idx) else self.PAIR.swapRemove(arch_idx);

        if (moved_id) |mid| {
            self.indices.items[mid] = arch_idx;
        }

        self.entity_gen.items[handle.id] += 1;
        self.free_indices.append(self.allocator, handle.id) catch unreachable;
    }

    pub fn updateAll(self: *Registry, dt: f32, vw: f32, vh: f32, move_speed: f32, jump_force: f32, gravity: f32) void { 
        inline for (.{ &self.PAIR, &self.PAR }) |archetype| {
            const T = @TypeOf(archetype.*);

            engine.systems.movement.update(T, archetype, move_speed, jump_force);
            engine.systems.physix.update(T, archetype, dt, gravity);
            engine.systems.animator.update(T, archetype);
            engine.systems.animation.update(T, archetype, dt);
            engine.systems.constraint.apply_screen_limits(T, archetype, vw, vh);
        }
    }

    pub fn drawAll(self: *Registry, r2d: *renderer.frontend.renderer2d.Renderer2D, inv_vh: f32) void {
        inline for (.{ &self.PAIR, &self.PAR }) |archetype| {
            const T = @TypeOf(archetype.*);
            renderer.systems.render.update(T, archetype, r2d, inv_vh);
        }
    }
};
