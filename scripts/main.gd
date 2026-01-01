extends Node2D

@export var surface_fraction: float = 0.33
@export var planet_radius_scale: float = 0.9

@onready var planet = $Planet
@onready var player = $Player

func _ready() -> void:
	_update_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var surface_height = viewport_size.y * surface_fraction
	var radius = viewport_size.x * planet_radius_scale
	var center = Vector2(viewport_size.x * 0.5, viewport_size.y - surface_height + radius)

	planet.set_planet(center, radius)
	player.planet_center = center
	player.planet_radius = radius

	var spawn_direction = Vector2(0.0, -1.0)
	player.global_position = center + spawn_direction * (radius + player.radius)
