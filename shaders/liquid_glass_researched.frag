#version 460 core

precision mediump float;

uniform vec2 uResolution;
uniform float uTime;
uniform float uIntensity;
uniform vec3 uEffectColor;
uniform sampler2D uSdfTexture;

out vec4 fragColor;

// Smooth minimum function for metaball union
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Simple noise function
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Fractal noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;
    
    // Apply time-based distortion for liquid effect
    vec2 distortion = vec2(
        sin(uv.y * 10.0 + uTime * 2.0) * 0.01,
        cos(uv.x * 8.0 + uTime * 1.5) * 0.01
    );
    
    vec2 distortedUv = uv + distortion * uIntensity;
    
    // Sample the SDF texture
    float sdfValue = texture(uSdfTexture, distortedUv).r;
    
    // Convert from 0-1 range to signed distance
    float signedDistance = (sdfValue - 0.5) * 2.0;
    
    // Create multiple metaball layers for depth
    float layer1 = signedDistance;
    float layer2 = signedDistance + 0.1 * sin(uTime * 3.0 + uv.x * 20.0);
    float layer3 = signedDistance + 0.05 * fbm(uv * 5.0 + uTime * 0.5);
    
    // Union the layers with smooth minimum
    float combined = smin(layer1, layer2, 0.1);
    combined = smin(combined, layer3, 0.05);
    
    // Create the liquid glass effect
    float edge = smoothstep(-0.1, 0.1, combined);
    float innerGlow = smoothstep(-0.3, -0.1, combined);
    float outerGlow = smoothstep(0.1, 0.3, combined);
    
    // Color mixing
    vec3 glowColor = uEffectColor * 1.5;
    
    // Final color composition
    vec3 finalColor = mix(
        glowColor * innerGlow,
        uEffectColor * (1.0 - edge),
        edge
    );
    
    // Add outer glow
    finalColor += glowColor * outerGlow * 0.3;
    
    // Apply intensity
    finalColor *= uIntensity;
    
    // Output with alpha based on effect strength
    float alpha = max(innerGlow, max(edge, outerGlow)) * uIntensity;
    fragColor = vec4(finalColor, alpha);
}