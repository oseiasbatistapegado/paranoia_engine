const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "paranoia_engine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .link_libc = true,
            .optimize = optimize,
        }),
        .use_llvm = false,
    });

    b.installArtifact(exe);

    const zmath = b.dependency("zmath", .{});
    exe.root_module.addImport("zmath", zmath.module("root"));

    const registry_path = b.graph.environ_map.get("VULKAN_REGISTRY").?;
    const vulkan = b.dependency("vulkan", .{
        .registry = registry_path,
    }).module("vulkan-zig");
    exe.root_module.addImport("vulkan", vulkan);

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("libs/c/c.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.addIncludePath(b.path("libs"));
    translate_c.linkSystemLibrary("sdl3", .{});

    const module_c = translate_c.createModule();
    module_c.addCSourceFile(.{ .file = b.path("libs/stb/stb_impl.c"), .flags = &[_][]const u8{} });
    exe.root_module.addImport("c", module_c);

    const platform = b.addModule("platform", .{
        .root_source_file = b.path("src/platform/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    platform.addImport("vulkan", vulkan);
    platform.addImport("c", module_c);
    exe.root_module.addImport("platform", platform);

    const engine = b.addModule("engine", .{
        .root_source_file = b.path("src/engine/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    engine.addImport("engine", engine);
    engine.addImport("platform", platform);
    engine.addImport("zmath", zmath.module("root"));
    exe.root_module.addImport("engine", engine);

    const game = b.addModule("game", .{
        .root_source_file = b.path("src/game/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    game.addImport("platform", platform);
    game.addImport("engine", engine);
    exe.root_module.addImport("game", game);

    const renderer = b.addModule("render", .{
        .root_source_file = b.path("src/renderer/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    engine.addImport("renderer", renderer);
    renderer.addImport("c", module_c);
    renderer.addImport("platform", platform);
    renderer.addImport("engine", engine);
    renderer.addImport("vulkan", vulkan);
    renderer.addImport("zmath", zmath.module("root"));
    renderer.addImport("renderer", renderer);
    exe.root_module.addImport("renderer", renderer);

    const vert_cmd = b.addSystemCommand(&.{
        "glslc",
        "--target-env=vulkan1.2",
        "-o",
    });
    const vert_spv = vert_cmd.addOutputFileArg("vert.spv");
    vert_cmd.addFileArg(b.path("src/renderer/backend/shaders/vertex.vert"));
    renderer.addAnonymousImport("vertex_shader", .{
        .root_source_file = vert_spv,
    });

    const frag_cmd = b.addSystemCommand(&.{
        "glslc",
        "--target-env=vulkan1.2",
        "-o",
    });
    const frag_spv = frag_cmd.addOutputFileArg("frag.spv");
    frag_cmd.addFileArg(b.path("src/renderer/backend/shaders/fragment.frag"));
    renderer.addAnonymousImport("fragment_shader", .{
        .root_source_file = frag_spv,
    });

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
