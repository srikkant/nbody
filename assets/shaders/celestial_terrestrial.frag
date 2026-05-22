#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float glow_intensity; // 0.0 = pure hard edge, 0.15 = thin atmo halo

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);

    float core = 1.0 - smoothstep(0.245, 0.25, dist);
    float halo = (1.0 - smoothstep(0.25, 0.30, dist)) * glow_intensity;
    float inner_shadow = smoothstep(0.20, 0.245, dist) * 0.15;

    float alpha = max(core * (1.0 - inner_shadow), halo) * fragColor.a;

    finalColor = vec4(fragColor.rgb * (1.0 - inner_shadow * 0.3), alpha);
}
