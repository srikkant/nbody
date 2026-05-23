#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float seconds;
uniform vec2 camera_target;
uniform float camera_zoom;
uniform vec2 screen_size;
uniform float grid_spacing;
uniform float grid_line_width;
uniform vec4 grid_color;

uniform int well_count;
uniform vec4 wells[16]; // vec4(x, y, mass, radius)
uniform float gravity_constant;
uniform float warp_strength;

void main() {
    vec2 screen_pos = (fragTexCoord - vec2(0.5)) * screen_size;
    vec2 world_pos = camera_target + screen_pos / camera_zoom;

    vec2 displacement = vec2(0.0);
    float softening = 30.0; // Tighter softening for sharper planet warps

    for (int i = 0; i < well_count; ++i) {
        vec4 well = wells[i];
        vec2 well_pos = well.xy;
        float mass = well.z;
        float radius = well.w;

        vec2 diff = well_pos - world_pos;
        float d = length(diff);

        float mass_warp = sqrt(mass);
        float warp_radius = radius * 3.0;

        float influence = (gravity_constant * mass_warp * warp_radius) / (d + radius * 0.2 + softening);
        displacement += normalize(diff) * influence;
    }

    vec2 warped_pos = world_pos + displacement * warp_strength;
    vec2 grid_uv = warped_pos / grid_spacing;
    vec2 grid_dist = abs(fract(grid_uv - 0.5) - 0.5) * grid_spacing;

    float dist_to_line = min(grid_dist.x, grid_dist.y);

    float pixel_size_world = 1.5 / camera_zoom;
    float half_width = grid_line_width * 0.5;

    float line_intensity = 1.0 - smoothstep(half_width - pixel_size_world, half_width + pixel_size_world, dist_to_line);
    float glow_width = grid_line_width * 4.0;
    float glow_intensity = 1.0 - smoothstep(half_width, glow_width + pixel_size_world, dist_to_line);

    float grid_val = line_intensity * 0.6 + glow_intensity * 0.4;

    float wave1 = sin((fragTexCoord.x + fragTexCoord.y) * 3.0 - seconds * 1.2);
    float wave2 = cos((fragTexCoord.x - fragTexCoord.y) * 2.0 + seconds * 0.8);
    float shimmer = 0.35 + 0.65 * (0.5 * wave1 + 0.5 * wave2 + 1.0) / 2.0;

    vec4 final_grid = grid_color * grid_val * shimmer;

    float zoom_fade = smoothstep(0.005, 0.02, camera_zoom);
    final_grid.a *= zoom_fade * 0.25; // Subtle overall alpha

    finalColor = final_grid * fragColor;
}
