// File: assets/shaders/metaball_shader.frag
#version 300 es

// This line is required for GLSL ES shaders.
precision highp float;

// The output variable for the final pixel color.
out vec4 outColor;

// Uniforms (data passed from Flutter).
uniform float uTime;
uniform vec2 uResolution;
uniform float uWidgetCount;
uniform vec4 uColor;

// The maximum number of widgets we can process.
// This MUST match the array size below.
const int MAX_WIDGETS = 64;
uniform vec4 uWidgets[MAX_WIDGETS]; // (x, y, width, height) for each widget.

// Smooth minimum function - the core of the metaball effect.
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Signed Distance Function for a circle/ellipse.
float sdCircle(vec2 p, vec2 c, vec2 r) {
    vec2 q = abs(p - c) - r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

void main() {
    // Get the coordinate of the current pixel.
    vec2 fragCoord = gl_FragCoord.xy;

    // Start with a very large distance.
    float dist = 10000.0;

    // The "Loop and Break" pattern: Loop up to the constant maximum.
    for (int i = 0; i < MAX_WIDGETS; i++) {
        // Break out of the loop if we've processed all active widgets.
        if (i >= int(uWidgetCount)) {
            break;
        }

        // Extract data for the current widget.
        vec2 pos = uWidgets[i].xy;
        vec2 size = uWidgets[i].zw;
        vec2 center = pos + size * 0.5;
        vec2 radius = size * 0.5;

        // Calculate the distance from the pixel to the widget's shape.
        float circleDist = sdCircle(fragCoord, center, radius);

        // Blend the current distance with the accumulated distance.
        // The '80.0' is the "blobbiness" factor.
        dist = smin(dist, circleDist, 80.0);
    }

    // Create a smooth anti-aliased edge for the final shape.
    float alpha = 1.0 - smoothstep(-1.5, 1.5, dist);

    // Set the final pixel color.
    outColor = vec4(uColor.rgb, alpha * uColor.a);
}