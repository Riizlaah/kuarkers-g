shader_type spatial;

uniform vec3 color_a: source_color;
uniform float rough: hint_range(0.0, 1.0)= 0.0001;
uniform sampler2D normal_map;
uniform vec2 wave_dir = vec2(0.005, 0.0);
uniform float time_scale: hint_range(0.0, 1.0) = 0.0005;

void fragment() {
	vec2 time = (TIME * wave_dir) * time_scale;
	vec3 normal = texture(normal_map, UV + time).rgb;
	ALBEDO = color_a;
	NORMAL_MAP = normal;
}

