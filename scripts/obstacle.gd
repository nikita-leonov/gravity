extends Node2D

@export var size: float = 24.0
@export var color: Color = Color(0.9, 0.15, 0.15)

func _ready() -> void:
	_update_visual()

func set_size(new_size: float) -> void:
	size = new_size
	_update_visual()

func _update_visual() -> void:
	var polygon = $Polygon2D
	if polygon == null:
		return
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		Vector2(-size * 0.5, -size * 0.5),
		Vector2(size * 0.5, -size * 0.5),
		Vector2(size * 0.5, size * 0.5),
		Vector2(-size * 0.5, size * 0.5)
	])
