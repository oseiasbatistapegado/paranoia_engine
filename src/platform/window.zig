const std = @import("std");
const c = @import("c");
const vk = @import("vulkan");

pub const Window = struct {
    handle: *c.SDL_Window,
    width: u32,
    height: u32,
    resized: bool = false,

    pub fn init(title: [:0]const u8, width: u32, height: u32) !Window {
        if (c.SDL_Init(c.SDL_INIT_VIDEO) == false) return error.SDLInitFailed;

        const handle = c.SDL_CreateWindow(
            title,
            @intCast(width),
            @intCast(height),
            c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE,
        ) orelse return error.WindowInitFailed;

        return .{
            .handle = handle,
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Window) void {
        c.SDL_DestroyWindow(self.handle);
        c.SDL_Quit();
    }

    pub fn getExtent(self: *Window) vk.Extent2D {
        var w: c_int = 0;
        var h: c_int = 0;

        _ = c.SDL_GetWindowSize(self.handle, &w, &h);

        return .{ .width = @intCast(w), .height = @intCast(h) };
    }

    pub fn hasResized(self: *Window) bool {
        var w: c_int = 0;
        var h: c_int = 0;
        _ = c.SDL_GetWindowSize(self.handle, &w, &h);

        const new_w: u32 = @intCast(w);
        const new_h: u32 = @intCast(h);

        if (new_w != self.width or new_h != self.height or self.resized) {
            self.width = new_w;
            self.height = new_h;
            self.resized = false;

            return true;
        }

        return false;
    }
};
