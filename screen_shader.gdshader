shader_type canvas_item;

uniform vec4 bg_color : source_color;
uniform vec2 resolution = vec2(1152.0, 648.0);
uniform vec4 outline_color : source_color;
uniform float outline_width;
uniform float smoothing_amount;
/**
* 0 - circle
* 1 - triangle
* 2 - box
*/
uniform int[3] shape_indices;
uniform float[3] shape_sizes;
uniform vec2[3] positions;
uniform vec4[3] shape_colors : source_color;

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

float smin_from_array(float[3] value_array, vec4[3] color_array, out vec4 color) {
	float min_value = value_array[0];
	vec4 min_color = color_array[0];
	for (int i = 1; i < value_array.length(); i++)
	{
		float value = value_array[i];
		vec4 color = color_array[i];
		vec2 smin_result = smin(min_value, value, smoothing_amount);
		min_color = mix(min_color, shape_colors[i], smin_result.y);
		min_value = smin_result.x;
	}
	color = min_color;
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

float box_sdf(vec2 pos, vec2 shape_pos, vec2 size)
{
	pos -= shape_pos;
	vec2 d = abs(pos) - size;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdf(vec2 pos, out vec4 color) {
	float[3] values;
	vec4[3] colors;
	for (int i = 0; i <= positions.length(); i++) {
		switch (shape_indices[i])
		{
			case 0: {
				values[i] = circle_sdf(positions[i], pos, shape_sizes[i]);
				colors[i] = shape_colors[i];
				break;
			}
			case 1: {
				values[i] = triangle_sdf(positions[i], pos, shape_sizes[i]);
				colors[i] = shape_colors[i];
				break;
			}
			case 2: {
				values[i] = box_sdf(positions[i], pos, vec2(shape_sizes[i]));
				colors[i] = shape_colors[i];
				break;
			}
		}
	}
	vec4 color_result;
	float smin_result = smin_from_array(values, colors, color_result);
	color = color_result;
	return smin_result;
}
 
void fragment() { 
	vec2 uv = UV * resolution;

	vec4 color;
	float sdf_result = sdf(uv, color);
	float dist = sdf_result;
	if (dist > 0.0001 && dist <= outline_width) {
		COLOR = outline_color;
	} else
	COLOR = mix(color, bg_color, step(0.0001, dist));
} 
