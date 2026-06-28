#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float r = length(uv);

    float target_radius = 0.42;
    float dist = r - target_radius;

    // Asymmetric blast wave profile (sharp front, soft trailing tail)
    float front_decay = 180.0; // very sharp outer edge
    float tail_decay = 25.0;    // softer inner edge/glow
    float glow = dist > 0.0 ? exp(-dist * front_decay) : exp(dist * tail_decay);

    // Ultra-bright core right at the shock front
    float core = exp(-abs(dist) * 300.0);

    // Ripple dome behind the shockwave
    float dome = 0.0;
    if (r < target_radius) {
        float ripple_speed = 22.0;
        float ripple_freq = 60.0;
        float ripples = sin(r * ripple_freq - seconds * ripple_speed) * 0.5 + 0.5;

        // Fade ripples near the center
        float center_fade = smoothstep(0.02, 0.18, r);
        
        // Slower decay for dome ripples
        dome = pow(1.0 - (r / target_radius), 1.5) * (0.25 + ripples * 0.20 * center_fade);
    }

    // Mix the base neon color (from Odin) with hot white at the core
    vec3 base_color = fragColor.rgb;
    vec3 hot_white = vec3(1.0, 1.0, 1.0);
    vec3 final_rgb = mix(base_color, hot_white, core * 0.9);

    // Calculate alpha (combining front glow, core, and internal dome)
    float alpha = clamp(glow * 0.8 + core * 1.0 + dome * 0.4, 0.0, 1.0);

    // Add HDR-like bloom to final RGB based on core and glow intensity
    finalColor = vec4(final_rgb * (1.0 + core * 1.5 + glow * 0.5), alpha * fragColor.a);
}

