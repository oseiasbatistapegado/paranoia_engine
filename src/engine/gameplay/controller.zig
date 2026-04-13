const std = @import("std");
const core = @import("core");
const engine = @import("engine");

pub const Controller = struct {
    move_vec: [2]f32 = .{ 0.0, 0.0 },
    wants_to_jump: bool = false,

    pub fn updateFromInput(self: *Controller, in: *core.input.InputManager) void {
        self.move_vec[0] = in.getAxis(.move_left, .move_right);
        self.move_vec[1] = in.getAxis(.move_up, .move_down);
        self.wants_to_jump = in.justPressed(.jump);
    }

    pub fn applyToEntity(self: *Controller, entity: *engine.ecs.entity.Entity) void {
        entity.intent.move_x = self.move_vec[0];
        entity.intent.move_y = self.move_vec[1];
        entity.intent.jump = self.wants_to_jump;
    }
};
