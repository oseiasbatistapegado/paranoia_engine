#version 450


layout(location = 0) in vec2 a_pos;
layout(location = 1) in vec2 a_uv;


layout(location = 2) in vec4 i_model_col0;
layout(location = 3) in vec4 i_model_col1;
layout(location = 4) in vec4 i_model_col2;
layout(location = 5) in vec4 i_model_col3;
layout(location = 6) in vec2 i_uv_offset;
layout(location = 7) in vec2 i_uv_scale;
layout(location = 8) in uint i_tex_id;

layout(push_constant) uniform PushConstants {
    mat4 view_proj;
} pc;

layout(location = 0) out vec2 v_uv;
layout(location = 1) flat out uint v_tex_id;

void main() {
    mat4 instance_model = mat4(
        i_model_col0, 
        i_model_col1, 
        i_model_col2, 
        i_model_col3
    );

    gl_Position = pc.view_proj * instance_model * vec4(a_pos, 0.0, 1.0);
    


    v_uv = (a_uv * i_uv_scale) + i_uv_offset;
    
    v_tex_id = i_tex_id;
}
