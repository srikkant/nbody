#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform sampler2D texture0;
uniform float seconds;

void main() {
    vec2 texelSize = vec2(1.0 / 1920.0, 1.0 / 1080.0);
    float glowSize = 4.0;

    vec4 sum = vec4(0.0);
    sum += texture(texture0, fragTexCoord) * 0.36;
    sum += texture(texture0, fragTexCoord + vec2(texelSize.x * glowSize, 0.0)) * 0.16;
    sum += texture(texture0, fragTexCoord - vec2(texelSize.x * glowSize, 0.0)) * 0.16;
    sum += texture(texture0, fragTexCoord + vec2(0.0, texelSize.y * glowSize)) * 0.16;
    sum += texture(texture0, fragTexCoord - vec2(0.0, texelSize.y * glowSize)) * 0.16;

    vec4 baseColor = texture(texture0, fragTexCoord);
    vec4 glowColor = sum * 4.0;
    vec4 finalGrid = baseColor + glowColor;

    float wave1 = sin((fragTexCoord.x + fragTexCoord.y) * 45.0 - seconds * 2.8);
    float wave2 = cos((fragTexCoord.x - fragTexCoord.y) * 35.0 + seconds * 2.0);
    float shimmer = 0.15 + 0.85 * (0.5 * wave1 + 0.5 * wave2 + 1.0) / 2.0;

    finalGrid.rgb *= shimmer;

    finalGrid.a = finalGrid.a * shimmer * 0.4;
    finalColor = finalGrid * fragColor;
}
