#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
out vec4 finalColor;

void main() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(fragTexCoord, center);

    vec4 texColor = texture(texture0, fragTexCoord);
    float glow = 1.0 - smoothstep(0.3, 0.6, dist);

    finalColor = vec4(texColor.rgb * glow, glow);
}
