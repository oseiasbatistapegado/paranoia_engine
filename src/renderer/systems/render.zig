const engine = @import("engine");
const renderer = @import("renderer");

pub fn update(comptime T: type, registry: *T, r2d: *renderer.frontend.renderer2d.Renderer2D, inv_vh: f32) void {
    for (0..registry.count) |i| {
        r2d.drawEntity(
            registry.x.items[i],
            registry.y.items[i],
            registry.z.items[i],

            registry.state.items[i],
            registry.facing_left.items[i],
            registry.current_frame.items[i],

            registry.texture_id.items[i],
            registry.config.items[i],

            registry.cached_scale_w.items[i],
            registry.cached_scale_h.items[i],

            inv_vh,
        );
    }
}
