const std = @import("std");
const vk = @import("vulkan");
const c = @import("c");
const zmath = @import("zmath");
const core = @import("core");
const engine = @import("engine");
const renderer = @import("renderer");
const zstbi = @import("zstbi");

const app_name = "Paranoia Engine";

pub fn main() !void {
    var window = try core.window.Window.init(app_name, 1920, 1080);
    defer window.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    zstbi.init(allocator);
    defer zstbi.deinit();

    const gc = try renderer.backend.context.GraphicsContext.init(allocator, app_name, window.handle);
    defer gc.deinit();

    var renderer2d = try renderer.frontend.renderer2d.Renderer2D.init(&gc, allocator, 1000);
    defer renderer2d.deinit(&gc, allocator);

    var asset_manager = renderer.frontend.assets.AssetManager.init(allocator);
    defer asset_manager.deinit(&gc);

    const current_extent = window.getExtent();
    var swapchain = try renderer.backend.swapchain.Swapchain.init(&gc, allocator, current_extent);
    defer swapchain.deinit();

    const pipeline_state = try renderer.backend.pipeline.RenderPipeline.init(&gc, swapchain, renderer2d.layout);
    defer pipeline_state.deinit();

    var frame_manager = try renderer.backend.frame_manager.FrameManager.init(&gc, allocator, swapchain, pipeline_state.layout, pipeline_state.handle, pipeline_state.render_pass);
    defer frame_manager.deinit();

    var staging = try gc.beginStaging(frame_manager.pool);

    const orc_tex = try asset_manager.loadTexture(&gc, &staging, engine.animation.ORC_CONFIG.texture_path);
    const orc_tex_id = renderer2d.registerTexture(&gc, orc_tex);

    const soldier_tex = try asset_manager.loadTexture(&gc, &staging, engine.animation.SOLDIER_CONFIG.texture_path);
    const soldier_tex_id = renderer2d.registerTexture(&gc, soldier_tex);

    var triangle_mesh = try renderer.frontend.mesh.Mesh.init(&gc, &staging, &renderer.frontend.defaults.vertices, &renderer.frontend.defaults.index);
    defer triangle_mesh.deinit();

    try gc.endStaging(&staging);
    staging.deinit(&gc);

    const images_in_flight = try allocator.alloc(vk.Fence, swapchain.swap_images.len);
    @memset(images_in_flight, .null_handle);
    defer allocator.free(images_in_flight);

    var camera = renderer.frontend.camera.Camera2D.init(
        @floatFromInt(window.width),
        @floatFromInt(window.height),
    );

    var entity_manager = engine.entity_manager.EntityManager.init(allocator);
    defer entity_manager.deinit();

    var player = engine.entity.Entity.init(
        .{ .x = -150, .y = 0, .z = 0.2 },
        orc_tex_id,
        &engine.animation.ORC_CONFIG,
    );

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    const inv_vh = 1.0 / camera.viewport_height;

    for (0..998) |_| {
        const rand_x = (random.float(f32) * 2.0 - 1.0) * camera.viewport_width;

        const rand_y = (random.float(f32) * 2.0 - 1.0) * camera.viewport_height;

        _ = try entity_manager.spawn(&engine.animation.SOLDIER_CONFIG, soldier_tex_id, rand_x, rand_y);
    }

    var player_controller = engine.controller.Controller{};

    const GRAVITY: f32 = 1200.0;
    const JUMP_FORCE: f32 = 600.0;
    const move_speed: f32 = 500.0;

    var input = try core.input.InputManager.init(allocator);
    defer input.deinit();

    var clock = try core.time.Clock.init(60.0);
    var frame_idx: u32 = 0;
    var state: renderer.backend.swapchain.Swapchain.PresentState = .optimal;
    var quit = false;

    while (!quit) {
        const dt = clock.tick();

        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT) quit = true;
        }

        input.update();
        if (input.justPressed(.quit)) quit = true;

        if (state == .suboptimal or window.hasResized()) {
            try gc.dev.deviceWaitIdle();
            try swapchain.recreate(window.getExtent());
            try frame_manager.refresh_resources(swapchain);
            @memset(images_in_flight, .null_handle);
            state = .optimal;
            clock.reset();
            camera.viewport_height = @floatFromInt(window.height);
            camera.viewport_width = @floatFromInt(window.width);
            continue;
        }

        player_controller.updateFromInput(input);
        player_controller.applyToEntity(&player, move_speed, JUMP_FORCE);

        entity_manager.updateAll(dt, camera.viewport_width, camera.viewport_height, GRAVITY);
        player.update(dt, camera.viewport_width, camera.viewport_height, GRAVITY);

        renderer2d.begin();
        renderer2d.drawEntity(player, inv_vh);
        entity_manager.drawAll(&renderer2d, inv_vh);
        try renderer2d.end(&gc);

        const img_idx = try frame_manager.beginFrame(swapchain, frame_idx, images_in_flight);
        const cmd = frame_manager.command_buffers[img_idx];

        const vp_matrix = zmath.mul(camera.getViewMatrix(), camera.getProjectionMatrix());
        var camera_push_data: [16]f32 = undefined;
        zmath.storeMat(&camera_push_data, vp_matrix);

        try frame_manager.beginCommandBuffer(cmd);
        {
            frame_manager.beginRenderPass(cmd, frame_manager.frame_buffers[img_idx], swapchain.extent);

            renderer2d.draw(
                &gc,
                cmd,
                pipeline_state.layout,
                triangle_mesh,
                camera_push_data,
            );

            frame_manager.endRenderPass(cmd);
        }
        try frame_manager.endCommandBuffer(cmd);

        frame_manager.endFrame(swapchain, frame_idx, img_idx) catch |err| {
            if (err == error.OutOfDateKHR) state = .suboptimal else return err;
        };

        clock.sleep();
        frame_idx = (frame_idx + 1) % @as(u32, @intCast(frame_manager.in_flight_fences.len));
    }
    try gc.dev.deviceWaitIdle();
}
