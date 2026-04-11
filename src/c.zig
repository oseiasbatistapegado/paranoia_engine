const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_vulkan.h");
});

pub const SDL_GetKeyboardState = c.SDL_GetKeyboardState;
pub const SDL_Scancode = c.SDL_Scancode;
pub const SDL_SCANCODE_A = c.SDL_SCANCODE_A;
pub const SDL_SCANCODE_W = c.SDL_SCANCODE_W;
pub const SDL_SCANCODE_D = c.SDL_SCANCODE_D;
pub const SDL_SCANCODE_S = c.SDL_SCANCODE_S;
pub const SDL_SCANCODE_ESCAPE = c.SDL_SCANCODE_ESCAPE;
pub const SDL_SCANCODE_SPACE = c.SDL_SCANCODE_SPACE;

pub const SDL_INIT_VIDEO = c.SDL_INIT_VIDEO;
pub const SDL_WINDOW_VULKAN = c.SDL_WINDOW_VULKAN;
pub const SDL_WINDOW_RESIZABLE = c.SDL_WINDOW_RESIZABLE;

pub const SDL_Window = c.SDL_Window;
pub const SDL_Delay = c.SDL_Delay;
pub const SDL_Init = c.SDL_Init;
pub const SDL_Quit = c.SDL_Quit;
pub const SDL_Event = c.SDL_Event;
pub const SDL_EVENT_QUIT = c.SDL_EVENT_QUIT;
pub const SDL_WINDOW_MINIMIZED = c.SDL_WINDOW_MINIMIZED;
pub const SDL_EVENT_WINDOW_RESIZED = c.SDL_EVENT_WINDOW_RESIZED;
pub const SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED = c.SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED;
pub const SDL_GetWindowFlags = c.SDL_GetWindowFlags;
pub const SDL_CreateWindow = c.SDL_CreateWindow;
pub const SDL_DestroyWindow = c.SDL_DestroyWindow;
pub const SDL_GetWindowSize = c.SDL_GetWindowSize;
pub const SDL_PollEvent = c.SDL_PollEvent;
pub const SDL_Vulkan_CreateSurface = c.SDL_Vulkan_CreateSurface;
pub const SDL_Vulkan_GetInstanceExtensions = c.SDL_Vulkan_GetInstanceExtensions;
pub const SDL_Vulkan_GetVkGetInstanceProcAddr = c.SDL_Vulkan_GetVkGetInstanceProcAddr;
