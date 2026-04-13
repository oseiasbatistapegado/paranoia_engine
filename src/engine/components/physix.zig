pub const PhysixComponent = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,
    dx: f32 = 0.0,
    dy: f32 = 0.0,
    dz: f32 = 0.0,

    friction: f32 = 0.1,

    pub fn setVelocity(self: *PhysixComponent, vx: f32, vy: f32) void {
        self.dx = vx;
        self.dy = vy;
    }
};
