#version 300 es
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform float uResolution_x;
uniform float uResolution_y;
uniform float uEffectMode;
uniform float uBlobSize;
uniform float uSmoothUnionStrength;
uniform float uDistortionStrength;
uniform float uRefractionStrength;
uniform float uEdgeThickness;
uniform float uNoiseScale;
uniform float uWidgetCount;
uniform float uPos0_x;
uniform float uPos0_y;
uniform float uPos1_x;
uniform float uPos1_y;
uniform float uPos2_x;
uniform float uPos2_y;
uniform float uPos3_x;
uniform float uPos3_y;
uniform float uPos4_x;
uniform float uPos4_y;
uniform float uPos5_x;
uniform float uPos5_y;
uniform float uPos6_x;
uniform float uPos6_y;
uniform float uPos7_x;
uniform float uPos7_y;

uniform sampler2D uTexture0;
uniform sampler2D uTexture1;
uniform sampler2D uTexture2;
uniform sampler2D uTexture3;
uniform sampler2D uTexture4;
uniform sampler2D uTexture5;
uniform sampler2D uTexture6;
uniform sampler2D uTexture7;

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

// Get widget position by index
vec2 getWidgetPos(int index) {
    if (index == 0) return vec2(uPos0_x, uPos0_y);
    else if (index == 1) return vec2(uPos1_x, uPos1_y);
    else if (index == 2) return vec2(uPos2_x, uPos2_y);
    else if (index == 3) return vec2(uPos3_x, uPos3_y);
    else if (index == 4) return vec2(uPos4_x, uPos4_y);
    else if (index == 5) return vec2(uPos5_x, uPos5_y);
    else if (index == 6) return vec2(uPos6_x, uPos6_y);
    else if (index == 7) return vec2(uPos7_x, uPos7_y);
    return vec2(0.5);
}

// Scene SDF combining all widget blobs
float sceneSDF(vec2 uv) {
    float result = 10.0;
    int widgetCount = int(uWidgetCount);
    
    for (int i = 0; i < 8; i++) {
        if (i >= widgetCount) break;
        
        vec2 pos = getWidgetPos(i);
        
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

// Sample widget texture based on index
vec4 sampleWidgetTexture(int index, vec2 uv) {
    uv = clamp(uv, 0.0, 1.0);
    
    if (index == 0) return texture(uTexture0, uv);
    else if (index == 1) return texture(uTexture1, uv);
    else if (index == 2) return texture(uTexture2, uv);
    else if (index == 3) return texture(uTexture3, uv);
    else if (index == 4) return texture(uTexture4, uv);
    else if (index == 5) return texture(uTexture5, uv);
    else if (index == 6) return texture(uTexture6, uv);
    else if (index == 7) return texture(uTexture7, uv);
    
    return vec4(0.0, 0.0, 0.0, 1.0);
}

void main() {
    vec2 resolution = vec2(uResolution_x, uResolution_y);
    vec2 uv = FlutterFragCoord().xy / resolution;
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
    vec4 finalColor = vec4(0.0, 0.0, 0.0, 1.0);
    float totalWeight = 0.0;
    int widgetCount = int(uWidgetCount);
    
    for (int i = 0; i < 8; i++) {
        if (i >= widgetCount) break;
        
        vec2 pos = getWidgetPos(i);
        float dist = distance(distortedUV, pos);
        float weight = 1.0 / (1.0 + dist * 10.0);
        
        // Sample base and refracted colors
        vec4 baseColor = sampleWidgetTexture(i, distortedUV);
        vec4 refractedColor = sampleWidgetTexture(i, refractOffset);
        
        // Blend based on edge distance
        vec4 blendedColor = mix(refractedColor, baseColor, edge);
        
        finalColor += blendedColor * weight;
        totalWeight += weight;
    }
    
    // Normalize by total weight
    if (totalWeight > 0.0) {
        finalColor /= totalWeight;
    }
    
    // Apply glass effect
    float glassEffect = 1.0 - edge * 0.3;
    finalColor.rgb *= glassEffect;
    
    // Add highlight near edges
    if (d < 0.02) {
        finalColor.rgb += vec3(0.1) * (1.0 - edge);
    }
    
    fragColor = finalColor;
}

/*
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
uniform float uWidgetPositions[16]; // 8 widgets * 2 coordinates each

uniform sampler2D uTexture0;
uniform sampler2D uTexture1;
uniform sampler2D uTexture2;
uniform sampler2D uTexture3;
uniform sampler2D uTexture4;
uniform sampler2D uTexture5;
uniform sampler2D uTexture6;
uniform sampler2D uTexture7;

out vec4 fragColor;

// Hash function for noise
vec2 hash2(inout vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453);
}

// Noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(dot(hash2(i + vec2(0.0)), f - vec2(0.0)),
                   dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                   dot(hash2(i + vec2(1.0)), f - vec2(1.0)), u.x), u.y);
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
    float result = 10.0; // Start with a large distance
    
    int widgetCount = int(uWidgetCount);
    
    // Use explicit comparison instead of min() function
    int maxWidgets = widgetCount < 8 ? widgetCount : 8;
    
    for (int i = 0; i < maxWidgets; i++) {
        // Get widget position
        vec2 pos = vec2(uWidgetPositions[i * 2], uWidgetPositions[i * 2 + 1]);
        
        // Add subtle animation to blob positions
        pos += vec2(sin(uTime + float(i)), cos(uTime * 1.1 + float(i))) * 0.01;
        
        // Calculate distance to this blob
        float blobDist = blobSDF(uv, pos, uBlobSize);
        
        // Combine with previous blobs using smooth union
        if (i == 0) {
            result = blobDist;
        } else {
            result = smoothUnion(result, blobDist, uSmoothUnionStrength);
        }
    }
    
    return result;
}

// Sample widget texture based on index
vec4 sampleWidgetTexture(int index, vec2 uv) {
    if (index == 0) return texture(uTexture0, uv);
    else if (index == 1) return texture(uTexture1, uv);
    else if (index == 2) return texture(uTexture2, uv);
    else if (index == 3) return texture(uTexture3, uv);
    else if (index == 4) return texture(uTexture4, uv);
    else if (index == 5) return texture(uTexture5, uv);
    else if (index == 6) return texture(uTexture6, uv);
    else if (index == 7) return texture(uTexture7, uv);
    return vec4(0.0);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Apply distortion if enabled
    vec2 distortedUV = uv;
    if (uEffectMode > 0.5) {
        distortedUV += vec2(
            noise(uv * uNoiseScale + vec2(uTime)),
            noise(uv * uNoiseScale * 1.1 - vec2(uTime))
        ) * uDistortionStrength;
    }
    
    // Calculate distance to liquid glass surface
    float d = sceneSDF(distortedUV);
    
    // Create smooth edge
    float edge = smoothstep(-uEdgeThickness, uEdgeThickness, d);
    
    // Refraction offset
    vec2 refractOffset = distortedUV + vec2(
        sin(uTime * 3.0),
        cos(uTime * 2.5)
    ) * uRefractionStrength;
    
    // Blend all widget textures based on proximity
    vec4 finalColor = vec4(0.0);
    float totalWeight = 0.0;
    
    int widgetCount = int(uWidgetCount);
    int maxWidgets = widgetCount < 8 ? widgetCount : 8;
    
    for (int i = 0; i < maxWidgets; i++) {
        vec2 pos = vec2(uWidgetPositions[i * 2], uWidgetPositions[i * 2 + 1]);
        
        // Calculate weight based on distance to widget
        float dist = distance(distortedUV, pos);
        float weight = 1.0 / (1.0 + dist * 10.0);
        
        // Sample base and refracted colors
        vec4 baseColor = sampleWidgetTexture(i, distortedUV);
        vec4 refractedColor = sampleWidgetTexture(i, refractOffset);
        
        // Blend based on edge
        vec4 blendedColor = mix(refractedColor, baseColor, edge);
        
        finalColor += blendedColor * weight;
        totalWeight += weight;
    }
    
    // Normalize by total weight
    if (totalWeight > 0.0) {
        finalColor /= totalWeight;
    }
    
    // Apply glass effect
    float glassEffect = 1.0 - edge * 0.3;
    finalColor.rgb *= glassEffect;
    
    // Add highlight near edges
    if (d < 0.02) {
        finalColor.rgb += vec3(0.1) * (1.0 - edge);
    }
    
    fragColor = vec4(finalColor.rgb, 1.0);
}
*/