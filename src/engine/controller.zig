const std = @import("std");
const core = @import("core");
const ent = @import("entity.zig");

pub const Controller = struct {
    move_vec: [2]f32 = .{ 0.0, 0.0 },
    wants_to_jump: bool = false,

    pub fn updateFromInput(self: *Controller, in: core.input.InputManager) void {
        self.move_vec[0] = in.getAxis(.move_left, .move_right);
        self.move_vec[1] = in.getAxis(.move_up, .move_down);
        self.wants_to_jump = in.justPressed(.jump);
    }

    pub fn applyToEntity(self: Controller, entity: *ent.Entity, move_speed: f32, jump_force: f32) void {
        entity.physix.dx = self.move_vec[0] * move_speed;
        entity.physix.dy = self.move_vec[1] * move_speed;

        if (self.wants_to_jump and entity.physix.z <= 0) {
            entity.physix.dz = jump_force;
        }
    }
};
