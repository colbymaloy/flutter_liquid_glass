#version 300 es
precision mediump float;

// Uniforms passed from Flutter:
//   uTexture   - sampler2D containing the captured widget image.
//   uResolution - vec2 representing canvas width and height.
//   uTime       - float representing the current time in seconds.
//   uEffectMode - float; 0.0 for basic effect, 1.0 for advanced distortion.
uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform float uEffectMode;

out vec4 fragColor;

// 2D hash function to support noise generation.
vec2 hash2(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Simple 2D noise function.
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float n = mix(
    mix(dot(hash2(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
        dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)),
        u.x),
    mix(dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
        dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)),
        u.x),
    u.y);
  return n;
}

// Defines a simple signed distance function (SDF) for a circular blob.
float blobSDF(vec2 uv, vec2 center, float radius) {
  return length(uv - center) - radius;
}

// Combines two SDFs using smooth union to allow soft blending between shapes.
float smoothUnion(float d1, float d2, float k) {
  float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
  return mix(d2, d1, h) - k * h * (1.0 - h);
}

// Constructs a scene SDF using two moving blobs.
float sceneSDF(vec2 uv, float time) {
  float d1 = blobSDF(uv, vec2(0.4 + 0.05 * sin(time), 0.5 + 0.05 * cos(time)), 0.2);
  float d2 = blobSDF(uv, vec2(0.6 + 0.05 * cos(time * 1.1), 0.5 + 0.05 * sin(time * 1.2)), 0.2);
  return smoothUnion(d1, d2, 0.1);
}

void main() {
  // Normalize pixel coordinates.
  vec2 uv = gl_FragCoord.xy / uResolution.xy;
  
  // In advanced effect mode, add distortion based on time and noise.
  if (uEffectMode > 0.5) {
    uv += 0.02 * vec2(noise(uv * 10.0 + uTime), noise(uv * 12.0 - uTime));
  }
  
  // Compute the SDF value from our scene.
  float d = sceneSDF(uv, uTime);
  // Determine edge softness using smoothstep.
  float thickness = 0.01;
  float edge = smoothstep(-thickness, thickness, d);
  
  // Compute a slight refraction offset.
  vec2 refractOffset = uv + 0.03 * vec2(sin(uTime * 3.0), cos(uTime * 2.5));
  
  // Sample the base texture normally and with the refracted coordinates.
  vec4 baseColor = texture(uTexture, uv);
  vec4 refractedColor = texture(uTexture, refractOffset);
  
  // Blend based on the SDF edge value to create a liquid, glass-like transition.
  vec4 color = mix(refractedColor, baseColor, edge);
  
  fragColor = vec4(color.rgb, 1.0);
}
