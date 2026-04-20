const std = @import("std");

pub const Clock = struct {
    io: std.Io,
    // timer: std.Io.Timestamp,
    target_fps: f64,
    target_ns: i96,
    last_frame_ns: i96,
    dt: f32,

    pub fn init(io: std.Io, target_fps: f64) !Clock {
        var timer = std.Io.Timestamp.now(io, .real);
        // var timer = try std.time.Timer.start();
        const target_ns = @as(i96, @intFromFloat((1.0 / target_fps) * std.time.ns_per_s));

        return Clock{
            .io = io,
            // .timer = timer,
            .target_fps = target_fps,
            .target_ns = target_ns,

            .last_frame_ns = timer.toNanoseconds(),
            .dt = 0.0,
        };
    }

    pub fn tick(self: *Clock) f32 {
        const current_ns = std.Io.Timestamp.now(self.io, .real).toNanoseconds();
        // const current_ns = self.timer.read();
        const frame_time_ns = current_ns - self.last_frame_ns;
        self.last_frame_ns = current_ns;

        const raw_dt = @as(f32, @floatCast(@as(f64, @floatFromInt(frame_time_ns)) / std.time.ns_per_s));

        self.dt = @min(raw_dt, 0.1);
        return self.dt;
    }

    pub fn sleep(self: *Clock) !void {
        const end_work_ns = std.Io.Timestamp.now(self.io, .real).toNanoseconds();
        const work_done_ns = end_work_ns - self.last_frame_ns;

        if (work_done_ns < self.target_ns) {
            const sleep_duration = self.target_ns - work_done_ns;
            try std.Io.sleep(self.io, .{ .nanoseconds = sleep_duration }, .real);
            // std.Thread.sleep(sleep_duration);
        }
    }

    pub fn reset(self: *Clock) void {
        self.last_frame_ns = std.Io.Timestamp.now(self.io, .real).toNanoseconds();
        // self.last_frame_ns = self.timer.read();
        self.dt = 0.0;
    }
};
