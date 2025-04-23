@tool
extends ColorRect

var positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

func _process(delta: float) -> void:
	material.set_shader_parameter("positions", positions)
