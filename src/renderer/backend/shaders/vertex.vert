#version 450

layout(location = 0) in vec2 a_pos;
layout(location = 1) in vec2 a_uv;

// Dados da Instância simplificados
layout(location = 2) in vec3 i_pos;      // x, visual_y, depth
layout(location = 3) in vec2 i_scale;    // sw, sh
layout(location = 4) in vec2 i_uv_offset;
layout(location = 5) in vec2 i_uv_scale;
layout(location = 6) in uint i_tex_id;

layout(push_constant) uniform PushConstants {
    mat4 view_proj;
} pc;

layout(location = 0) out vec2 v_uv;
layout(location = 1) flat out uint v_tex_id;

void main() {
    // Escala o vértice e translada para a posição final
    // Como é 2D, usamos i_pos.z para o depth test do Vulkan
    vec3 world_pos = vec3(a_pos * i_scale, 0.0) + vec3(i_pos.xy, i_pos.z);
    
    gl_Position = pc.view_proj * vec4(world_pos, 1.0);

    v_uv = (a_uv * i_uv_scale) + i_uv_offset;
    v_tex_id = i_tex_id;
}
