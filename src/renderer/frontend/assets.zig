const std = @import("std");
const renderer = @import("renderer");
const GraphicsContext = renderer.backend.context.GraphicsContext;
const Texture = renderer.backend.texture.Texture;
const zstbi = @import("zstbi");

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

        var image = try zstbi.Image.loadFromFile(path_c, 4);
        defer image.deinit();

        const tex = try gc.createTextureDeferred(staging, image.width, image.height, image.data);

        try self.textures.put(path, tex);
        return tex;
    }
};
