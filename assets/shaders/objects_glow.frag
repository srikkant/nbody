#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);

    float core = 1.0 - smoothstep(0.24, 0.25, dist);
    float halo = 1.0 - smoothstep(0.20, 0.5, dist);

    float pulse = 0.5 + 0.5 * sin(seconds * 1.5);
    float halo_mod = 0.2 + 0.4 * pulse;

    float alpha = max(core, halo * halo_mod) * fragColor.a;

    float mix_factor = pulse * 0.4;
    vec3 yellowish = vec3(0.95, 1, 0.4);
    vec3 color = mix(fragColor.rgb, yellowish, mix_factor);

    color *= (1.0 + 0.1 * pulse);

    finalColor = vec4(color, alpha);
}
