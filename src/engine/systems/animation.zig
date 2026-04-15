const engine = @import("engine");

pub fn update(comptime T: type, registry: *T, dt: f32) void {
    for (0..registry.count) |i| {
        const current_anim = registry.config.items[i].getAnim(registry.state.items[i]);
        registry.timer.items[i] += dt;

        if (registry.timer.items[i] > (1.0 / current_anim.speed)) {
            registry.timer.items[i] = 0;
            registry.current_frame.items[i] += 1;

            if (registry.current_frame.items[i] >= current_anim.frame_count) {
                registry.current_frame.items[i] = if (current_anim.loop) 0 else current_anim.frame_count - 1;
            }
        }
    }
}
