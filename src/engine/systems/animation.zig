const engine = @import("engine");

pub fn update(
    state: []engine.components.animation.AnimationState,
    frame: []u32,
    timer: []f32,
    configs: []*const engine.components.animation.SpriteConfig,
    count: u64,
    dt: f32,
) void {
    for (0..count) |i| {
        const current_anim = configs[i].getAnim(state[i]);
        timer[i] += dt;

        if (timer[i] > (1.0 / current_anim.speed)) {
            timer[i] = 0;
            frame[i] += 1;

            if (frame[i] >= current_anim.frame_count) {
                frame[i] = if (current_anim.loop) 0 else current_anim.frame_count - 1;
            }
        }
    }
}
