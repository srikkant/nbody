#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;

float energyPattern(vec2 p, float t) {
    float v = 0.0;
    v += sin(p.x * 12.0 + t * 3.5) * 0.4;
    v += sin(p.y * 10.0 - t * 2.8) * 0.4;
    v += sin((p.x + p.y) * 9.0 + t * 1.9) * 0.3;
    v += sin(length(p) * 16.0 - t * 4.2) * 0.3;
    return v;
}

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float r = length(uv);

    if (r > 0.48) {
        discard;
    }

    float t = seconds * 1.5;
    float angle = atan(uv.y, uv.x);

    float distortion = energyPattern(uv * 3.5, t) * 0.12;
    float perturbedRadius = r + distortion;

    // 0.25 is approximately the physics radius (1/4 of quad boundary)
    float core = 1.0 - smoothstep(0.0, 0.18, perturbedRadius);
    float plasma = 1.0 - smoothstep(0.12, 0.42, perturbedRadius);

    float shift = sin(t * 0.7 + angle * 2.0) * 0.5 + 0.5;
    vec3 col_blue = vec3(0.05, 0.35, 1.0); // Deep vibrant blue
    vec3 col_purple = vec3(0.55, 0.05, 0.95); // Glowing purple/magenta
    vec3 col_cyan = vec3(0.00, 0.95, 0.90); // Sparkling neon cyan

    vec3 baseColor = mix(col_blue, col_purple, shift);
    baseColor = mix(baseColor, col_cyan, cos(t * 1.1) * 0.4 + 0.4);
    vec3 finalRGB = mix(baseColor, vec3(1.0, 1.0, 1.0), core * 0.85);
    float flares = pow(max(0.0, sin(angle * 3.0 + t * 1.5) * sin(angle * 2.0 - t * 0.8)), 4.0) * 0.35;

    float alpha = (plasma + core * 0.4 + flares) * (1.0 - smoothstep(0.40, 0.48, r));
    alpha = clamp(alpha, 0.0, 1.0);

    finalColor = vec4(finalRGB * (1.1 + core * 0.4), alpha * fragColor.a);
}
