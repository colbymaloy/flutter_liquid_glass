#version 460 core
#include <flutter/runtime_effect.glsl>

// Uniforms: Variables passed from Dart to the shader.
uniform sampler2D uImage;
uniform vec2 uResolution;
uniform float uBlur;
uniform float uContrast;

// The output color of the fragment.
out vec4 fragColor;

void main() {
    // Normalize the fragment's screen coordinates to UV coordinates [0, 1].
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // --- Step 1: Blur the Alpha Channel ---
    // This is the core of the metaball effect. We sample neighboring pixels
    // and average their alpha values. This creates a smooth gradient where
    // widgets are close to each other, effectively "merging" them.

    float totalAlpha = 0.0;
    float kernelSize = uBlur * 2.0 + 1.0;
  
    // A simple box blur. For higher quality, a Gaussian blur could be used.
    for (float x = -uBlur; x <= uBlur; x += 1.0) {
        for (float y = -uBlur; y <= uBlur; y += 1.0) {
            vec2 offset = vec2(x, y) / uResolution;
            totalAlpha += texture(uImage, uv + offset).a;
        }
    }
    float blurredAlpha = totalAlpha / (kernelSize * kernelSize);

    // --- Step 2: Increase Contrast ---
    // The blur makes everything fuzzy. We need to sharpen the result to get
    // defined blob shapes. We can do this by manipulating the alpha curve.
  
    // We use a smoothstep function to create a sharp transition.
    // The 'contrast' uniform controls how tight this transition is.
    float alphaThreshold = 0.5;
    float sharpenedAlpha = smoothstep(alphaThreshold - (1.0 / uContrast), alphaThreshold + (1.0 / uContrast), blurredAlpha);

    // --- Step 3: Combine with Original Color ---
    // We want the blobs to have the color of the original widgets.
    // We sample the original color from the input image.
    vec4 originalColor = texture(uImage, uv);

    // The final color is the original widget color, but with our new,
    // calculated blob alpha. We multiply by the sharpenedAlpha to ensure
    // that areas outside the blob are fully transparent.
    fragColor = vec4(originalColor.rgb, originalColor.a * sharpenedAlpha);
}
