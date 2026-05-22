#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

// 0.0 = Particle (glowing spark), 1.0 = Shockwave (neon ring + translucent dome)
uniform float u_vfx_type;
uniform float seconds;

void main() {
    vec2 uv = fragTexCoord - vec2(0.5);
    float r = length(uv);

    if (u_vfx_type > 0.5) {
        float target_radius = 0.42;
        float dist_to_ring = abs(r - target_radius);

        float core_ring = 1.0 - smoothstep(0.0, 0.015, dist_to_ring);
        float glow_ring = 1.0 - smoothstep(0.0, 0.055, dist_to_ring);

        float ring = core_ring * 2.2 + glow_ring * 0.8;

        float dome = 0.0;
        if (r < target_radius) {
            float ripple_speed = 18.0;
            float ripple_freq = 55.0;
            float ripples = sin(r * ripple_freq - seconds * ripple_speed) * 0.5 + 0.5;

            // Soften ripples near the center so they originate cleanly
            float center_fade = smoothstep(0.02, 0.15, r);

            dome = pow(1.0 - (r / target_radius), 1.0) * (0.35 + ripples * 0.25 * center_fade);
        }

        float alpha = ring + dome;
        vec3 hot_glow_color = fragColor.rgb * (1.0 + core_ring * 1.5 + glow_ring * 0.5);

        finalColor = vec4(hot_glow_color, alpha * fragColor.a);
    } else {
        // Particles
        float core = 1.0 - smoothstep(0.0, 0.16, r);
        float glow = 1.0 - smoothstep(0.0, 0.50, r);

        float alpha = core + glow * 0.45;
        alpha *= (1.0 - smoothstep(0.42, 0.50, r));

        vec3 final_rgb = fragColor.rgb * (1.1 + core * 0.6);
        finalColor = vec4(final_rgb, alpha * fragColor.a);
    }
}
