#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

void main() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(fragTexCoord, center);
    float glow = 1.0 - smoothstep(0.4, 0.6, dist);

    finalColor = vec4(fragColor.rgb * glow, glow);
}
