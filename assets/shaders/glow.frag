#version 100

precision mediump float;

varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;

void main() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(fragTexCoord, center);

    vec4 texColor = texture2D(texture0, fragTexCoord);
    float glow = 1.0 - smoothstep(0.3, 0.6, dist);

    gl_FragColor = vec4(texColor.rgb * glow, glow);
}
