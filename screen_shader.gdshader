shader_type canvas_item;

uniform vec4 bg_color : source_color;
uniform vec2 resolution = vec2(1152.0, 648.0);
uniform float smoothing_amount;
/**
* 0 - circle
* 1 - triangle
* 2 - box
*/
uniform int[3] shape_indices;
uniform float[3] shape_sizes;
uniform vec2[3] positions;
uniform vec3[3] colors : source_color;

/*
math
shamelessly stolen from https://iquilezles.org/articles/smin/
*/

vec2 smin( float a, float b, float k ) {
	float h = 1.0 - min(abs(a - b) / (4.0 * k), 1.0);
	float w = h * h;
	float m = w * 0.5;
	float s = w * k;
	return (a < b) ? vec2(a - s, m) : vec2(b - s, 1.0 - m);
}

vec4 smin_from_array(vec4[3] array) {
	vec4 min_value = array[0];
	for (int i = 1; i < array.length(); i++)
	{
		vec4 value = array[i];
		vec2 smin_result = smin(min_value.w, value.w, smoothing_amount);
		min_value.rgb = mix(min_value.rgb, colors[i], smin_result.y);
		min_value.w = smin_result.x;
	}
	return min_value;
}

float circle_sdf(vec2 pos, vec2 shape_pos, float radius) {
	float dist = length(pos - shape_pos) - radius;
	return dist;
}

float triangle_sdf(vec2 pos, vec2 shape_pos, float radius)
{
	pos -= shape_pos;
	const float k = sqrt(3.0);
	pos.x = abs(pos.x) - radius;
	pos.y = pos.y + radius/k;
	if (pos.x + k * pos.y > 0.0) pos = vec2(pos.x - k * pos.y, - k * pos.x - pos.y) / 2.0;
	pos.x -= clamp(pos.x, -2.0 * radius, 0.0);
	return -length(pos) * sign(pos.y);
}

float box_sdf(vec2 pos, vec2 shape_pos, vec2 b )
{
	pos -= shape_pos;
	vec2 d = abs(pos) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdf(vec2 pos, out vec3 color) {
	vec4[3] shapes;
	for (int i = 0; i <= positions.length(); i++) {
		switch (shape_indices[i])
		{
			case 0: {
				shapes[i].w = circle_sdf(positions[i], pos, shape_sizes[i]);
				shapes[i].xyz = colors[i];
				break;
			}
			case 1: {
				shapes[i].w = triangle_sdf(positions[i], pos, shape_sizes[i]);
				shapes[i].xyz = colors[i];
				break;
			}
			case 2: {
				shapes[i].w = box_sdf(positions[i], pos, vec2(shape_sizes[i]));
				shapes[i].xyz = colors[i];
				break;
			}
		}
	}
	vec4 smin_result = smin_from_array(shapes);
	color = smin_result.rgb;
	return smin_result.w;
}
 
void fragment() { 
	vec2 uv = UV * resolution;

	vec3 color;
	float sdf_result = sdf(uv, color);
	float dist = sdf_result;
	
	COLOR = mix(vec4(color, 1), bg_color, step(0.0001, dist));
} 
