@tool
extends Marker2D

@export var index: int
@export var color_rect: ColorRect

func _process(delta: float) -> void:
	color_rect.positions[index] = global_position
