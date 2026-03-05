#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// Gruvbox Material palette
const vec3 PAPER = vec3(0.941, 0.918, 0.839); // #f0ebd6 warm cream
const vec3 INK   = vec3(0.098, 0.098, 0.118); // #19191e soft charcoal

// --- Bayer 4x4 dithering ---
float bayer4x4(ivec2 p) {
    int x = p.x & 3;
    int y = p.y & 3;
    int idx = x + (y << 2);
    // Standard Bayer matrix normalized to 0..1
    float m[16] = float[16](
         0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
        12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
         3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
        15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
    );
    return m[idx];
}

// --- Hash noise (no trig, GPU-friendly) ---
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// --- Multi-octave paper texture ---
float paperTexture(vec2 uv) {
    float n = 0.0;
    n += hash12(uv * 0.3)  * 0.60; // very large fibers
    n += hash12(uv * 0.8)  * 0.40; // large fibers
    n += hash12(uv * 2.5)  * 0.30; // medium detail
    n += hash12(uv * 6.0)  * 0.20; // fine grain
    n += hash12(uv * 15.0) * 0.10; // very fine grain
    return n / 1.6;
}

// --- Directional grain (paper fiber direction) ---
float directionalGrain(vec2 uv) {
    vec2 dir = vec2(0.7, 0.3);
    float along = dot(uv, dir);
    float n = 0.0;
    n += hash12(vec2(along * 3.0, uv.y * 0.5)) * 0.6;
    n += hash12(vec2(along * 8.0, uv.y * 1.5)) * 0.4;
    return n;
}

// --- Vignette ---
float vignette(vec2 uv) {
    vec2 center = uv - 0.5;
    float dist = length(center);
    float vig = smoothstep(1.2, 0.4, dist);
    return mix(1.0, vig, 0.15);
}

void main() {
    vec4 color = texture(tex, v_texcoord);
    vec2 pixCoord = gl_FragCoord.xy;

    // 1. Luminance (BT.709)
    float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));

    // 2. Slight brightness lift
    gray = pow(gray, 0.9);

    // 3. Contrast with bite
    gray = smoothstep(0.03, 0.95, gray);

    // 4. Lift shadows - darkest maps to 0.12
    gray = mix(0.12, 1.0, gray);

    // 5. Paper texture
    float paper = paperTexture(pixCoord);
    float grain = directionalGrain(pixCoord);

    // Apply texture only to bright areas (paper region)
    float texMask = smoothstep(0.5, 0.95, gray);
    gray += (paper - 0.5) * 0.035 * texMask;
    gray += (grain - 0.5) * 0.025 * texMask * 0.7;

    // 6. Bayer dithering
    float dither = bayer4x4(ivec2(pixCoord));
    gray += (dither - 0.5) * 0.025;

    // 7. Subtle vignette
    gray *= vignette(v_texcoord) * 0.5 + 0.5;

    // 8. Clamp
    gray = clamp(gray, 0.0, 1.0);

    // 9. Color variation on paper (warmth)
    float colorVar = (hash12(pixCoord * 0.05) - 0.5) * 0.015;
    vec3 paperTinted = PAPER + vec3(colorVar, colorVar * 0.5, -colorVar * 0.2);

    // 10. Final mix: ink to paper
    vec3 finalColor = mix(INK, paperTinted, gray);

    fragColor = vec4(finalColor, 1.0);
}
