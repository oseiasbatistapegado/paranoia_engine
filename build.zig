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
    exe.root_module.linkSystemLibrary("sdl3", .{});

    const zmath = b.dependency("zmath", .{});
    exe.root_module.addImport("zmath", zmath.module("root"));

    const zstbi = b.dependency("zstbi", .{});
    exe.root_module.addImport("zstbi", zstbi.module("root"));

    const registry_path = std.process.getEnvVarOwned(b.allocator, "VULKAN_REGISTRY") catch "/path/to/vk.xml";
    const vulkan = b.dependency("vulkan_zig", .{
        .registry = registry_path,
    }).module("vulkan-zig");
    exe.root_module.addImport("vulkan", vulkan);

    const c = b.addModule("c", .{
        .root_source_file = b.path("src/c.zig"),
        .target = target,
        .optimize = optimize,
    });
    c.linkSystemLibrary("sdl3", .{});
    exe.root_module.addImport("c", c);

    const core = b.addModule("core", .{
        .root_source_file = b.path("src/core/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    core.addImport("vulkan", vulkan);
    core.addImport("c", c);
    exe.root_module.addImport("core", core);

    const engine = b.addModule("engine", .{
        .root_source_file = b.path("src/engine/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    engine.addImport("engine", engine);
    engine.addImport("core", core);
    engine.addImport("zmath", zmath.module("root"));
    exe.root_module.addImport("engine", engine);

    const renderer = b.addModule("render", .{
        .root_source_file = b.path("src/renderer/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    engine.addImport("renderer", renderer);
    renderer.addImport("c", c);
    renderer.addImport("core", core);
    renderer.addImport("engine", engine);
    renderer.addImport("vulkan", vulkan);
    renderer.addImport("zmath", zmath.module("root"));
    renderer.addImport("zstbi", zstbi.module("root"));
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
