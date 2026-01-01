extends Node2D

@export var radius: float = 600.0
@export var color: Color = Color(0.14, 0.16, 0.22)

var center: Vector2 = Vector2.ZERO

func _ready() -> void:
	queue_redraw()

func set_planet(center_position: Vector2, planet_radius: float) -> void:
	center = center_position
	radius = planet_radius
	queue_redraw()

func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(center, radius, color)
