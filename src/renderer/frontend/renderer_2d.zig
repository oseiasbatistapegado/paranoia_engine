const std = @import("std");
const vk = @import("vulkan");
const zmath = @import("zmath");
const renderer = @import("renderer");
const platform = @import("platform");
const engine = @import("engine");

pub const Renderer2D = struct {
    max_instances: u32,
    instance_count: u32 = 0,
    instance_buffers: [3]renderer.backend.types.Buffer,

    instances: []renderer.backend.types.InstanceData,
    mapped_data: [3][*]renderer.backend.types.InstanceData,
    descriptor_pool: vk.DescriptorPool,
    descriptor_set: vk.DescriptorSet,
    layout: vk.DescriptorSetLayout,
    current_frame: u32 = 0,
    next_slot: u32 = 0,

    pub fn init(gc: *const renderer.backend.context.GraphicsContext, allocator: std.mem.Allocator, max_instances: u32) !Renderer2D {
        var instance_buffers: [3]renderer.backend.types.Buffer = undefined;
        var mapped_data: [3][*]renderer.backend.types.InstanceData = undefined;

        for (0..3) |i| {
            instance_buffers[i] = try gc.createBuffer(
                @sizeOf(renderer.backend.types.InstanceData) * max_instances,
                .{ .vertex_buffer_bit = true },
                .{ .host_visible_bit = true, .host_coherent_bit = true },
            );
            const ptr = try gc.dev.mapMemory(instance_buffers[i].memory, 0, vk.WHOLE_SIZE, .{});
            mapped_data[i] = @ptrCast(@alignCast(ptr));
        }

        const instances = try allocator.alloc(renderer.backend.types.InstanceData, max_instances);
        const layout = try createBindlessLayout(gc);
        const pool_size = vk.DescriptorPoolSize{
            .type = .combined_image_sampler,
            .descriptor_count = 1000,
        };

        const pool = try gc.dev.createDescriptorPool(&.{
            .flags = .{ .update_after_bind_bit = true },
            .max_sets = 1,
            .pool_size_count = 1,
            .p_pool_sizes = @ptrCast(&pool_size),
        }, null);

        var set: vk.DescriptorSet = .null_handle;
        const variable_counts = [_]u32{1000};
        const count_info = vk.DescriptorSetVariableDescriptorCountAllocateInfo{
            .descriptor_set_count = 1,
            .p_descriptor_counts = &variable_counts,
        };

        try gc.dev.allocateDescriptorSets(&.{
            .p_next = &count_info,
            .descriptor_pool = pool,
            .descriptor_set_count = 1,
            .p_set_layouts = @ptrCast(&layout),
        }, @ptrCast(&set));

        return .{
            .max_instances = max_instances,
            .instance_buffers = instance_buffers,
            .instances = instances,
            .mapped_data = mapped_data,
            .descriptor_pool = pool,
            .descriptor_set = set,
            .layout = layout,
        };
    }

    pub fn deinit(self: *Renderer2D, gc: *const renderer.backend.context.GraphicsContext, allocator: std.mem.Allocator) void {
        for (0..3) |i| {
            gc.dev.unmapMemory(self.instance_buffers[i].memory);
            self.instance_buffers[i].deinit(gc.dev);
        }

        gc.dev.destroyDescriptorPool(self.descriptor_pool, null);
        gc.dev.destroyDescriptorSetLayout(self.layout, null);
        allocator.free(self.instances);
    }

    pub fn begin(self: *Renderer2D) void {
        self.instance_count = 0;
    }

    pub fn drawEntity(
        self: *Renderer2D,
        x: f32,
        y: f32,
        z: f32,

        state: engine.resources.animation.AnimationState,
        facing_left: bool,
        frame: u32,

        texture: u32,
        config: *const engine.resources.animation.SpriteConfig,

        sw: f32,
        sh: f32,
        inv_vh: f32,
    ) void {
        if (self.instance_count >= self.max_instances) return;

        const current_anim = config.getAnim(state);
        const total_cols = config.sheet_width / config.sprite_width;
        const total_rows = config.sheet_height / config.sprite_height;
        const frame_width = 1.0 / total_cols;
        const frame_height = 1.0 / total_rows;
        const padding = 0.0001;
        const col_index = @as(f32, @floatFromInt((current_anim.frame_start + frame) % @as(u32, @intFromFloat(total_cols))));
        const row_index = @as(f32, @floatFromInt(current_anim.row));

        var uv_s_x = frame_width - padding;
        var uv_o_x = (col_index * frame_width) + (padding / 2.0);

        if (facing_left) {
            uv_o_x += uv_s_x;
            uv_s_x *= -1.0;
        }

        self.instances[self.instance_count] = .{
            .model = computeMatrix(x, y, z, sw, sh, inv_vh),
            .uv_offset = .{ uv_o_x, (row_index * frame_height) + (padding / 2.0) },
            .uv_scale = .{ uv_s_x, frame_height - padding },
            .texture_id = texture,
        };

        self.instance_count += 1;
    }

    pub fn end(self: *Renderer2D, _: *const renderer.backend.context.GraphicsContext) !void {
        if (self.instance_count == 0) return;

        @memcpy(self.mapped_data[self.current_frame][0..self.instance_count], self.instances[0..self.instance_count]);
    }

    pub fn draw(
        self: *Renderer2D,
        gc: *const renderer.backend.context.GraphicsContext,
        cmd_buffer: vk.CommandBuffer,
        pipeline_layout: vk.PipelineLayout,
        mesh: renderer.frontend.mesh.Mesh,
        camera_matrix: [16]f32,
    ) void {
        if (self.instance_count == 0) return;

        const PConstants = struct {
            mvp: [16]f32,
        };
        const pc = PConstants{ .mvp = camera_matrix };

        gc.dev.cmdPushConstants(
            cmd_buffer,
            pipeline_layout,
            .{ .vertex_bit = true, .fragment_bit = true },
            0,
            @sizeOf(PConstants),
            &pc,
        );

        gc.dev.cmdBindDescriptorSets(
            cmd_buffer,
            .graphics,
            pipeline_layout,
            0,
            1,
            @ptrCast(&self.descriptor_set),
            0,
            null,
        );

        const offsets = [_]vk.DeviceSize{0};

        gc.dev.cmdBindVertexBuffers(cmd_buffer, 0, 1, @ptrCast(&mesh.vertex_buffer.handle), &offsets);
        gc.dev.cmdBindIndexBuffer(cmd_buffer, mesh.index_buffer.handle, 0, .uint16);

        gc.dev.cmdBindVertexBuffers(cmd_buffer, 1, 1, @ptrCast(&self.instance_buffers[self.current_frame].handle), &offsets);

        gc.dev.cmdDrawIndexed(cmd_buffer, mesh.index_count, self.instance_count, 0, 0, 0);

        self.current_frame = (self.current_frame + 1) % 3;
    }

    pub fn createBindlessLayout(gc: *const renderer.backend.context.GraphicsContext) !vk.DescriptorSetLayout {
        const binding = vk.DescriptorSetLayoutBinding{
            .binding = 0,
            .descriptor_type = .combined_image_sampler,
            .descriptor_count = 1000,
            .stage_flags = .{ .fragment_bit = true },
        };

        const flags = [_]vk.DescriptorBindingFlags{.{
            .partially_bound_bit = true,
            .variable_descriptor_count_bit = true,
            .update_after_bind_bit = true,
        }};

        const binding_flags = vk.DescriptorSetLayoutBindingFlagsCreateInfo{
            .binding_count = 1,
            .p_binding_flags = &flags,
        };

        return try gc.dev.createDescriptorSetLayout(&.{
            .p_next = &binding_flags,
            .flags = .{ .update_after_bind_pool_bit = true },
            .binding_count = 1,
            .p_bindings = @ptrCast(&binding),
        }, null);
    }

    pub fn registerTexture(self: *Renderer2D, gc: *const renderer.backend.context.GraphicsContext, tex: renderer.backend.texture.Texture) u32 {
        const slot = self.next_slot;
        const image_info = vk.DescriptorImageInfo{
            .sampler = tex.sampler,
            .image_view = tex.view,
            .image_layout = .shader_read_only_optimal,
        };

        const write = vk.WriteDescriptorSet{
            .dst_set = self.descriptor_set,
            .dst_binding = 0,
            .dst_array_element = slot,
            .descriptor_count = 1,
            .descriptor_type = .combined_image_sampler,
            .p_image_info = @ptrCast(&image_info),
            .p_buffer_info = undefined,
            .p_texel_buffer_view = undefined,
        };

        gc.dev.updateDescriptorSets(1, @ptrCast(&write), 0, null);
        self.next_slot += 1;
        return slot;
    }

    fn computeMatrix(
        x: f32,
        y: f32,
        z: f32,
        sw: f32,
        sh: f32,
        inv_vh: f32,
    ) zmath.Mat {
        const scale = zmath.scaling(sw, sh, 1.0);

        const half_vh = (0.5 / inv_vh);
        const normalized_y = (y + half_vh) * inv_vh;
        const depth = 0.9 + (normalized_y * -0.8);

        const visual_y = y - z;
        const translation = zmath.translation(x, visual_y, depth);

        return zmath.mul(scale, translation);
    }
};
