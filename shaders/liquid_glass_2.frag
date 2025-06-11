#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform float uBlurSigma;
uniform float uIntensity;
uniform float uSmoothness;
uniform float uColorShift;
uniform vec4 uGlassColor;
uniform float uGlassOpacity;
uniform float uRefractiveIndex;
uniform float uThickness;
uniform vec3 uLightDirection;

out vec4 fragColor;

// SDF operations
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

// Convert alpha to SDF
float alphaMaskToSDF(sampler2D tex, vec2 uv) {
    float alpha = texture(tex, uv).a;
    return (0.5 - alpha) * uThickness;
}

// Gaussian blur
vec4 gaussianBlur(sampler2D tex, vec2 uv, float sigma) {
    vec2 texelSize = 1.0 / uResolution;
    vec4 color = vec4(0.0);
    float totalWeight = 0.0;
    
    int kernelSize = int(ceil(sigma * 2.0));
    
    for (int x = -kernelSize; x <= kernelSize; x++) {
        for (int y = -kernelSize; y <= kernelSize; y++) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            float weight = exp(-0.5 * (float(x*x + y*y) / (sigma * sigma)));
            color += texture(tex, uv + offset) * weight;
            totalWeight += weight;
        }
    }
    
    return color / totalWeight;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Get SDF from alpha
    float sdf = alphaMaskToSDF(uTexture, uv);
    sdf = sdf / max(uSmoothness, 0.001);
    
    // Calculate alpha with anti-aliasing
    float alpha = 1.0 - smoothstep(-1.0, 1.0, sdf);
    
    if (alpha > 0.001) {
        // Glass effect calculations
        vec2 distortion = (uv - 0.5) * uIntensity * sdf;
        
        // Chromatic aberration
        vec3 color = vec3(
            texture(uTexture, uv + distortion * (1.0 + uColorShift)).r,
            texture(uTexture, uv + distortion).g,
            texture(uTexture, uv + distortion * (1.0 - uColorShift)).b
        );
        
        // Add glass tint and animation
        float pulse = sin(uTime * 2.0) * 0.1 + 1.0;
        color = mix(color, uGlassColor.rgb, uGlassOpacity * pulse);
        
        // Blur for glass effect
        vec4 blurred = gaussianBlur(uTexture, uv, uBlurSigma * 0.1);
        color = mix(color, blurred.rgb, 0.3);
        
        fragColor = vec4(color, alpha);
    } else {
        fragColor = texture(uTexture, uv);
    }
}