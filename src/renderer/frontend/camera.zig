const std = @import("std");
const zmath = @import("zmath");

pub const Camera2D = struct {
    position: zmath.Vec,
    zoom: f32 = 1.0,
    viewport_width: f32,
    viewport_height: f32,

    pub fn init(width: f32, height: f32) Camera2D {
        return .{
            .position = zmath.f32x4(0, 0, 0, 0),
            .viewport_width = width,
            .viewport_height = height,
        };
    }

    pub fn getProjectionMatrix(self: Camera2D) zmath.Mat {
        const right = self.viewport_width / 2.0 / self.zoom;
        const left = -right;
        const top = self.viewport_height / 2.0 / self.zoom;
        const bottom = -top;

        return zmath.orthographicOffCenterLh(left, right, top, bottom, 0.1, 100.0);
    }

    pub fn getViewMatrix(self: Camera2D) zmath.Mat {
        return zmath.translationV(-self.position);
    }
};
