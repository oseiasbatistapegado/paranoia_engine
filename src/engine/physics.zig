const std = @import("std");
const zmath = @import("zmath");

pub const Physics = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,
    dx: f32 = 0.0,
    dy: f32 = 0.0,
    dz: f32 = 0.0,

    friction: f32 = 0.1,

    pub fn update(self: *Physics, dt: f32, gravity: f32) void {
        self.x += self.dx * dt;
        self.y += self.dy * dt;

        if (self.z > 0 or self.dz > 0) {
            self.dz -= gravity * dt;
            self.z += self.dz * dt;
        }

        if (self.z < 0) {
            self.z = 0;
            self.dz = 0;
        }
    }

    pub fn setVelocity(self: *Physics, vx: f32, vy: f32) void {
        self.dx = vx;
        self.dy = vy;
    }
};
