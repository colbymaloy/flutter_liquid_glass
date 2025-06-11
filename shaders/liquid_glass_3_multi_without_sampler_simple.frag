#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform float uEffectMode;
uniform float uBlobSize;
uniform float uSmoothUnionStrength;
uniform float uDistortionStrength;
uniform float uRefractionStrength;
uniform float uEdgeThickness;
uniform float uNoiseScale;
uniform float uWidgetCount;
uniform float uWidgetPositions[16];

out vec4 fragColor;

// Hash function for noise generation
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453);
}

// Smooth noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)), 
            dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
        mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)), 
            dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// SDF for a blob/circle
float blobSDF(vec2 uv, vec2 center, float radius) {
    return length(uv - center) - radius;
}

// Smooth union operation for combining SDFs
float smoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

// Scene SDF combining all widget blobs
float sceneSDF(vec2 uv) {
    float result = 10.0;
    int widgetCount = int(uWidgetCount);
    
    // Use explicit loop bounds instead of min() function
    for (int i = 0; i < 8; i++) {
        if (i >= widgetCount) break;
        
        vec2 pos = vec2(uWidgetPositions[i * 2], uWidgetPositions[i * 2 + 1]);
        
        // Add subtle animation to blob positions
        pos += vec2(
            sin(uTime + float(i)) * 0.01,
            cos(uTime * 1.1 + float(i)) * 0.01
        );
        
        float blobDist = blobSDF(uv, pos, uBlobSize);
        
        if (i == 0) {
            result = blobDist;
        } else {
            result = smoothUnion(result, blobDist, uSmoothUnionStrength);
        }
    }
    
    return result;
}

// Generate procedural colors based on widget positions
vec3 getWidgetColor(int index, vec2 uv) {
    float hue = float(index) * 0.618034; // Golden ratio for nice color distribution
    hue = fract(hue);
    
    // Convert HSV to RGB
    vec3 c = vec3(hue, 0.8, 0.9);
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 distortedUV = uv;
    
    // Apply distortion effect if enabled
    if (uEffectMode > 0.5) {
        distortedUV += vec2(
            noise(uv * uNoiseScale + vec2(uTime)),
            noise(uv * uNoiseScale * 1.1 - vec2(uTime))
        ) * uDistortionStrength;
    }
    
    // Calculate distance to liquid glass surface
    float d = sceneSDF(distortedUV);
    
    // Create smooth edge transition
    float edge = smoothstep(-uEdgeThickness, uEdgeThickness, d);
    
    // Apply refraction offset
    vec2 refractOffset = distortedUV + vec2(
        sin(uTime * 3.0),
        cos(uTime * 2.5)
    ) * uRefractionStrength;
    
    // Blend colors from all widgets based on proximity
    vec3 finalColor = vec3(0.0);
    float totalWeight = 0.0;
    int widgetCount = int(uWidgetCount);
    
    for (int i = 0; i < 8; i++) {
        if (i >= widgetCount) break;
        
        vec2 pos = vec2(uWidgetPositions[i * 2], uWidgetPositions[i * 2 + 1]);
        float dist = distance(distortedUV, pos);
        float weight = 1.0 / (1.0 + dist * 10.0);
        
        // Get procedural color for this widget
        vec3 widgetColor = getWidgetColor(i, distortedUV);
        
        finalColor += widgetColor * weight;
        totalWeight += weight;
    }
    
    // Normalize by total weight
    if (totalWeight > 0.0) {
        finalColor /= totalWeight;
    }
    
    // Apply glass effect
    float glassEffect = 1.0 - edge * 0.3;
    finalColor *= glassEffect;
    
    // Add highlight near edges
    if (d < 0.02) {
        finalColor += vec3(0.1, 0.2, 0.3) * (1.0 - edge);
    }
    
    // Add some background when outside blobs
    if (d > 0.0) {
        finalColor = mix(finalColor, vec3(0.05, 0.05, 0.1), edge);
    }
    
    fragColor = vec4(finalColor, 1.0);
}	