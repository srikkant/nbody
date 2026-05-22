#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);
    float core = 1.0 - step(0.48, dist);

    finalColor = vec4(fragColor.rgb, core * fragColor.a);
}
