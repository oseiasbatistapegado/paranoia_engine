const engine = @import("engine");
const renderer = @import("renderer");

pub fn update(
    comptime T: type,
    registry: *T,
    r2d: *renderer.frontend.renderer2d.Renderer2D,
    camera: *renderer.frontend.camera.Camera2D,
    inv_vh: f32,
) void {
    const half_w = (camera.viewport_width * 0.5) / camera.zoom;
    const half_h = (camera.viewport_height * 0.5) / camera.zoom;

    const cam_x = camera.position[0];
    const cam_y = camera.position[1];

    const left = cam_x - half_w;
    const rigth = cam_x + half_w;
    const bottom = cam_y - half_h;
    const top = cam_y + half_h;

    for (0..registry.count) |i| {
        const x = registry.x.items[i];
        const y = registry.y.items[i];

        const half_sw = registry.cached_scale_w.items[i] * 0.5;
        const half_sh = registry.cached_scale_h.items[i] * 0.5;

        if (
            x + half_sw < left or
            x - half_sw > rigth or
            y + half_sh < bottom or
            y - half_sh > top
        ) continue;

        r2d.drawEntity(
            x,
            y,
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
