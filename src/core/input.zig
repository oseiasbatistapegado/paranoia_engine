const c = @import("c");
const std = @import("std");

pub const Action = enum {
    move_left,
    move_right,
    move_up,
    move_down,
    jump,
    quit,
};

pub const InputManager = struct {
    bindings: std.AutoHashMap(c.SDL_Scancode, Action),

    actions_down: std.EnumArray(Action, bool),

    actions_prev: std.EnumArray(Action, bool),

    pub fn init(allocator: std.mem.Allocator) !InputManager {
        var self = InputManager{
            .bindings = std.AutoHashMap(c.SDL_Scancode, Action).init(allocator),
            .actions_down = std.EnumArray(Action, bool).initFill(false),
            .actions_prev = std.EnumArray(Action, bool).initFill(false),
        };

        try self.bindings.put(c.SDL_SCANCODE_A, .move_left);
        try self.bindings.put(c.SDL_SCANCODE_D, .move_right);
        try self.bindings.put(c.SDL_SCANCODE_W, .move_up);
        try self.bindings.put(c.SDL_SCANCODE_S, .move_down);
        try self.bindings.put(c.SDL_SCANCODE_SPACE, .jump);
        try self.bindings.put(c.SDL_SCANCODE_ESCAPE, .quit);

        return self;
    }

    pub fn deinit(self: *InputManager) void {
        self.bindings.deinit();
    }

    pub fn update(self: *InputManager) void {
        for (std.enums.values(Action)) |action| {
            self.actions_prev.set(action, self.actions_down.get(action));
        }

        const key_state = c.SDL_GetKeyboardState(null);

        self.actions_down = std.EnumArray(Action, bool).initFill(false);

        var it = self.bindings.iterator();
        while (it.next()) |entry| {
            const scancode = entry.key_ptr.*;
            const action = entry.value_ptr.*;

            if (key_state[@intCast(scancode)]) {
                self.actions_down.set(action, true);
            }
        }
    }

    pub fn isPressed(self: InputManager, action: Action) bool {
        return self.actions_down.get(action);
    }

    pub fn justPressed(self: InputManager, action: Action) bool {
        return self.actions_down.get(action) and !self.actions_prev.get(action);
    }

    pub fn getAxis(self: InputManager, negative: Action, positive: Action) f32 {
        var axis: f32 = 0;
        if (self.isPressed(positive)) axis += 1.0;
        if (self.isPressed(negative)) axis -= 1.0;
        return axis;
    }
};
