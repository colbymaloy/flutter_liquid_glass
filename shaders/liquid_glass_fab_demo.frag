#version 460 core
#include <flutter/runtime_effect.glsl>

// --- UNIFORMS (Order is critical!) ---
uniform vec2 uSize;       // index 0, 1
uniform float uTime;      // index 2
uniform float uBlobbiness;// index 3
uniform float uWidgetCount; // index 4

// --- WIDGET DATA ARRAY ---
// THIS IS THE CRITICAL CHANGE
#define MAX_WIDGETS 7
uniform float uWidgets[MAX_WIDGETS * 5]; // index 5 onwards

out vec4 fragColor;

// --- Helper Functions (Unchanged) ---
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// --- Main Shader Logic ---
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    float min_dist = 1e20;
    int count = int(uWidgetCount);

    // This fixed loop now matches the allocated uniform size.
    for (int i = 0; i < MAX_WIDGETS; ++i) {
        if (i < count) {
            int baseIndex = i * 5;
            vec2 pos = vec2(uWidgets[baseIndex], uWidgets[baseIndex + 1]);
            vec2 size = vec2(uWidgets[baseIndex + 2], uWidgets[baseIndex + 3]);
            float radius = uWidgets[baseIndex + 4];
            vec2 center = pos + size * 0.5;
            vec2 halfSize = size * 0.5;
            float dist = sdRoundedBox(fragCoord - center, halfSize, radius);
            min_dist = smin(min_dist, dist, uBlobbiness);
        }
    }

    // Smoother anti-aliasing
    float alpha = 1.0 - smoothstep(0.0, 1.5, min_dist);
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}