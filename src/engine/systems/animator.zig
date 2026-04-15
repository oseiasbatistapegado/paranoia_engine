const engine = @import("engine");

pub fn update(comptime T: type, registry: *T) void {
    for (0..registry.count) |i| {
        const next_state: engine.resources.animation.AnimationState = if (registry.z.items[i] > 0) .jump
            else if (@abs(registry.dx.items[i]) > 0 or @abs(registry.dy.items[i]) > 0) .walk
            else .idle;

        if (registry.state.items[i] != next_state) {
            registry.state.items[i] = next_state;
            registry.current_frame.items[i] = 0;
            registry.timer.items[i] = 0;
        }

        if (registry.dx.items[i] != 0)
            registry.facing_left.items[i] = registry.dx.items[i] < 0;
    }
}
