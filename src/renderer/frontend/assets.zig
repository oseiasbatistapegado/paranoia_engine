const std = @import("std");
const renderer = @import("renderer");
const GraphicsContext = renderer.backend.context.GraphicsContext;
const Texture = renderer.backend.texture.Texture;
const c = @import("c");
// const zstbi = @import("zstbi");

pub const AssetManager = struct {
    allocator: std.mem.Allocator,
    textures: std.StringHashMap(Texture),

    pub fn init(allocator: std.mem.Allocator) AssetManager {
        return .{
            .allocator = allocator,
            .textures = std.StringHashMap(Texture).init(allocator),
        };
    }

    pub fn deinit(self: *AssetManager, gc: *const GraphicsContext) void {
        var it = self.textures.valueIterator();
        while (it.next()) |tex| {
            tex.deinit(gc.dev);
        }
        self.textures.deinit();
    }

    pub fn loadTexture(
        self: *AssetManager,
        gc: *const GraphicsContext,
        staging: *renderer.backend.context.StagingContext,
        path: []const u8,
    ) !renderer.backend.texture.Texture {
        if (self.textures.get(path)) |tex| return tex;

        const path_c = try self.allocator.dupeZ(u8, path);
        defer self.allocator.free(path_c);

        var width: c_int = 0;
        var height: c_int = 0;
        var channels: c_int = 0;

        const data = c.stbi_load(path_c, &width, &height, &channels, 4) orelse {
            return error.FailedToLoadImage;
        };
        defer c.stbi_image_free(data);

        const size = @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4;
        const pixels = @as([*]const u8, @ptrCast(data))[0..size];

        const tex = try gc.createTextureDeferred(staging, @intCast(width), @intCast(height), pixels);

        try self.textures.put(path, tex);
        return tex;
    }
};
