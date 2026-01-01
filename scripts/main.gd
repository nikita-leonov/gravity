extends Node2D

@export var surface_fraction: float = 0.33
@export var planet_radius_scale: float = 0.9
@export var obstacle_count: int = 6
@export var obstacle_size_range: Vector2 = Vector2(18.0, 34.0)

@onready var planet = $Planet
@onready var player = $Player
@onready var obstacles = $Obstacles

var obstacle_scene := preload("res://scenes/obstacle.tscn")

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
	_spawn_obstacles(center, radius)

	var spawn_direction = Vector2(0.0, -1.0)
	player.global_position = center + spawn_direction * (radius + player.radius)

func _spawn_obstacles(center: Vector2, radius: float) -> void:
	if obstacles == null:
		return

	for child in obstacles.get_children():
		child.queue_free()

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var count = max(obstacle_count, 0)
	var min_size = min(obstacle_size_range.x, obstacle_size_range.y)
	var max_size = max(obstacle_size_range.x, obstacle_size_range.y)

	for i in range(count):
		var obstacle = obstacle_scene.instantiate()
		obstacles.add_child(obstacle)

		var size = rng.randf_range(min_size, max_size)
		if obstacle.has_method("set_size"):
			obstacle.call("set_size", size)

		var angle = rng.randf_range(0.0, TAU)
		var direction = Vector2.RIGHT.rotated(angle)
		obstacle.global_position = center + direction * (radius + size * 0.5)
		obstacle.rotation = direction.angle() + PI * 0.5
