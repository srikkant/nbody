#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;
uniform float glow_intensity; // 0.4–0.7, controls glow envelope extent

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);

    float core = 1.0 - smoothstep(0.18, 0.22, dist);
    float envelope_edge = 0.22 + glow_intensity * 0.28;
    float envelope = (1.0 - smoothstep(0.20, envelope_edge, dist));
    float outer_glow = (1.0 - smoothstep(envelope_edge, 0.5, dist)) * glow_intensity * 0.3;
    float pulse = 0.85 + 0.15 * sin(seconds * 1.2) * glow_intensity;

    vec3 core_color = fragColor.rgb * 1.2;
    vec3 envelope_color = fragColor.rgb * 0.7;
    vec3 color = mix(envelope_color, core_color, core);

    float alpha = max(core, max(envelope * 0.6, outer_glow)) * fragColor.a * (0.85 + 0.15 * pulse);

    finalColor = vec4(color * (0.85 + 0.15 * pulse), alpha);
}
