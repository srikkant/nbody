#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    float core = 1.0 - smoothstep(0.0, 0.2, dist);
    float bloom1 = (1.0 - smoothstep(0.08, 0.35, dist)) * 0.7;
    float bloom2 = (1.0 - smoothstep(0.20, 0.5, dist)) * 0.3;
    float pulse = 0.9 + 0.1 * sin(seconds * 0.6);

    vec3 white = vec3(1.0, 1.0, 1.0);
    vec3 gold = fragColor.rgb;
    vec3 color = mix(gold, white, core * 0.85 + bloom1 * 0.3);

    float alpha = (core + bloom1 + bloom2) * fragColor.a * pulse;
    alpha = clamp(alpha, 0.0, 1.0);

    finalColor = vec4(color * (1.0 + core * 0.3), alpha);
}
