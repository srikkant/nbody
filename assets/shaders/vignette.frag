#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

out vec4 finalColor;

void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    vec2 uv = fragTexCoord - vec2(0.5);
    float dist = length(uv);

    float vignette = smoothstep(0.8, 0.4, dist);
    finalColor = texelColor * vignette * fragColor;
}
