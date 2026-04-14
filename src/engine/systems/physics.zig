const std = @import("std");
const engine = @import("engine");

pub fn update(
    x: []f32,
    y: []f32,
    z: []f32,
    dx: []f32,
    dy: []f32,
    dz: []f32,
    count: usize,
    dt: f32,
    gravity: f32,
) void {
    for (0..count) |i| {
        x[i] += dx[i] * dt;
        y[i] += dy[i] * dt;

        if (z[i] > 0 or dz[i] > 0) {
            dz[i] -= gravity * dt;
            z[i] += dz[i] * dt;
        }

        if (z[i] < 0) {
            z[i] = 0;
            dz[i] = 0;
        }
    }
}
