const engine = @import("engine");

pub fn update(
    move_x: []f32,
    move_y: []f32,
    jump: []bool,
    dx: []f32,
    dy: []f32,
    dz: []f32,
    z: []f32,
    count: usize,
    move_speed: f32,
    jump_force: f32,
) void {
    for (0..count) |i| {
        dx[i] = move_x[i] * move_speed;
        dy[i] = move_y[i] * move_speed;

        if (jump[i] and z[i] <= 0) {
            dz[i] = jump_force;
        }
    }
}
