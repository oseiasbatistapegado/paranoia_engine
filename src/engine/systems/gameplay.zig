const engine = @import("engine");

pub fn update(
    dx: []f32,
    dy: []f32,
    z: []f32,
    state: []engine.components.animation.AnimationState,
    facing_left: []bool,
    frame: []u32,
    timer: []f32,
    count: usize,
) void {
    for (0..count) |i| {
        const next_state: engine.components.animation.AnimationState = if (z[i] > 0) .jump
            else if (@abs(dx[i]) > 0 or @abs(dy[i]) > 0) .walk
            else .idle;

        if (state[i] != next_state) {
            state[i] = next_state;
            frame[i] = 0;
            timer[i] = 0;
        }

        if (dx[i] != 0)
            facing_left[i] = dx[i] < 0;
    }
}
