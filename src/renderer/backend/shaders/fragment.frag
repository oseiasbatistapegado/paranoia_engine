#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec2 v_uv;
layout(location = 1) flat in uint v_tex_id;

layout(location = 0) out vec4 f_color;

layout(set = 0, binding = 0) uniform sampler2D tex_samplers[];

void main() {

    vec4 color = texture(tex_samplers[nonuniformEXT(v_tex_id)], v_uv);
    


    if (color.a < 0.1) {
        discard;
    }
    

    f_color = color;
}
