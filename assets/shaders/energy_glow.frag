#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;

float energyPattern(vec2 p, float t) {
    float v = 0.0;
    v += sin(p.x * 5.5 + t * 2.0) * 0.35;
    v += sin(p.y * 4.8 - t * 1.8) * 0.35;
    v += sin((p.x + p.y) * 4.0 + t * 1.2) * 0.25;
    v += sin(length(p) * 6.5 - t * 2.2) * 0.25;
    return v;
}

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float r = length(uv);

    float t = seconds * 1.6;
    float angle = atan(uv.y, uv.x);

    float distortion = energyPattern(uv * 2.8, t) * 0.10;
    float perturbedRadius = r + distortion;

    float core = 1.0 - smoothstep(0.0, 0.18, perturbedRadius);
    float plasma = 1.0 - smoothstep(0.08, 0.42, perturbedRadius);

    // Color shifting across neon cyan, glowing magenta, and deep electric blue
    float shift = sin(t * 0.8 + angle * 2.0) * 0.5 + 0.5;
    vec3 col_blue = vec3(0.05, 0.40, 1.0); // Vibrant electric blue
    vec3 col_magenta = vec3(0.65, 0.05, 0.95); // Glowing magenta
    vec3 col_cyan = vec3(0.00, 0.95, 0.85); // Sparkling neon cyan

    vec3 baseColor = mix(col_blue, col_magenta, shift);
    baseColor = mix(baseColor, col_cyan, cos(t * 1.2) * 0.4 + 0.4);

    vec3 finalRGB = mix(baseColor, vec3(1.0, 1.0, 1.0), core * 0.85);

    float flares = pow(max(0.0, sin(angle * 3.0 + t * 1.2) * sin(angle * 2.0 - t * 0.6)), 4.0) * 0.25;
    float edgeFade = 1.0 - smoothstep(0.38, 0.50, r);
    float alpha = (plasma + core * 0.5 + flares) * edgeFade;
    alpha = clamp(alpha, 0.0, 1.0);

    finalColor = vec4(finalRGB * (1.2 + core * 0.4), alpha * fragColor.a);
}
