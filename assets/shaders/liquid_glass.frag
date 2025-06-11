#version 460 core
#include <flutter/runtime_effect.glsl>

const int MAX_BLOBS = 10;

out vec4 fragColor;

// --- Uniforms ---
uniform float u_viscosity;
uniform float u_is_soft_body;
uniform float u_is_3d_look;
uniform vec4 u_blobs[MAX_BLOBS];

// Samplers
uniform sampler2D u_texture0;
uniform sampler2D u_texture1;
uniform sampler2D u_texture2;
uniform sampler2D u_texture3;
uniform sampler2D u_texture4;
uniform sampler2D u_texture5;
uniform sampler2D u_texture6;
uniform sampler2D u_texture7;
uniform sampler2D u_texture8;
uniform sampler2D u_texture9;


// --- Functions ---
float my_smoothstep(float edge0, float edge1, float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

float calculate_field_at(vec2 point, vec2 blob_center, vec2 blob_size) {
    float radius = max(blob_size.x, blob_size.y) * 0.5;
    float dist_sq = dot(point - blob_center, point - blob_center);
    if (dist_sq < 0.0001) return 1000.0;
    return (radius * radius) / dist_sq;
}

float sum_total_field(vec2 point) {
    float total_field = 0.0;
    for (int i = 0; i < MAX_BLOBS; i++) {
        if (u_blobs[i].z <= 0.0) {
            continue;
        }
        total_field += calculate_field_at(point, u_blobs[i].xy, u_blobs[i].zw);
    }
    return total_field;
}

void main() {
    if (u_is_soft_body < 0.5) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 coords = FlutterFragCoord().xy;
    float total_field = sum_total_field(coords);
    float threshold = 1.0;
    float blob_alpha = my_smoothstep(threshold - u_viscosity, threshold + u_viscosity, total_field);

    if (blob_alpha < 0.01) {
        fragColor = vec4(0.0);
        return;
    }

    float max_influence = -1.0;
    int dominant_index = -1;
    for (int i = 0; i < MAX_BLOBS; i++) {
        if (u_blobs[i].z <= 0.0) {
            continue;
        }
        float influence = calculate_field_at(coords, u_blobs[i].xy, u_blobs[i].zw);
        if (influence > max_influence) {
            max_influence = influence;
            dominant_index = i;
        }
    }

    vec3 base_rgb;

    if (dominant_index != -1) {
        vec4 blob_data;
        vec2 uv;
        vec4 widget_pixel = vec4(0.0);

        switch(dominant_index) {
            case 0: blob_data = u_blobs[0]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture0, uv); } break;
            case 1: blob_data = u_blobs[1]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture1, uv); } break;
            case 2: blob_data = u_blobs[2]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture2, uv); } break;
            case 3: blob_data = u_blobs[3]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture3, uv); } break;
            case 4: blob_data = u_blobs[4]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture4, uv); } break;
            case 5: blob_data = u_blobs[5]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture5, uv); } break;
            case 6: blob_data = u_blobs[6]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture6, uv); } break;
            case 7: blob_data = u_blobs[7]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture7, uv); } break;
            case 8: blob_data = u_blobs[8]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture8, uv); } break;
            case 9: blob_data = u_blobs[9]; uv = (coords - (blob_data.xy - blob_data.zw * 0.5)) / blob_data.zw; if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) { widget_pixel = texture(u_texture9, uv); } break;
        }

        vec3 goo_color = vec3(0.8, 0.85, 1.0);
        float safe_alpha = max(widget_pixel.a, 0.001);
        vec3 true_widget_color = widget_pixel.rgb / safe_alpha;
        base_rgb = mix(goo_color, true_widget_color, widget_pixel.a);

    } else {
        base_rgb = vec3(0.8, 0.85, 1.0);
    }

    if (u_is_3d_look > 0.5) {
        float step = 2.0;
        float grad_x = sum_total_field(coords + vec2(step, 0.0)) - sum_total_field(coords - vec2(step, 0.0));
        float grad_y = sum_total_field(coords + vec2(0.0, step)) - sum_total_field(coords - vec2(0.0, -step));
        vec2 normal = normalize(vec2(grad_x, grad_y));
        vec3 light_dir = normalize(vec3(-1.0, -1.0, 1.0));
        float normal_z = sqrt(max(0.0, 1.0 - dot(normal, normal)));
        vec3 surface_normal = vec3(normal, normal_z);
        float diffuse = max(0.0, dot(surface_normal, light_dir));
        vec3 ambient = vec3(0.4);
        vec3 final_rgb = base_rgb * (ambient + diffuse * 0.8);
        fragColor = vec4(final_rgb, blob_alpha);
    } else {
        fragColor = vec4(base_rgb, blob_alpha);
    }
}