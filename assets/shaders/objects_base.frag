#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);

    // Assuming quad is drawn at 4x physics radius.
    // dist 0.25 = physics radius.
    // dist 0.5 = edge of quad.

    float core = 1.0 - smoothstep(0.24, 0.25, dist);
    float halo = 1.0 - smoothstep(0.20, 0.5, dist);

    float alpha = max(core, halo * 0.5) * fragColor.a;

    finalColor = vec4(fragColor.rgb, alpha);
}
