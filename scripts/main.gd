extends Node2D

@export var surface_fraction: float = 0.33
@export var planet_radius_scale: float = 0.9
@export var obstacle_count: int = 6
@export var obstacle_size_range: Vector2 = Vector2(18.0, 34.0)
@export var satellite_count: int = 3
@export var satellite_orbit_offset: float = 140.0
@export var satellite_orbit_gap: float = 90.0
@export var satellite_radius_range: Vector2 = Vector2(80.0, 140.0)
@export var satellite_orbit_speed_range: Vector2 = Vector2(0.25, 0.85)

@onready var planet = $Planet
@onready var player = $Player
@onready var obstacles = $Obstacles
@onready var satellites = $Satellites

var obstacle_scene := preload("res://scenes/obstacle.tscn")
var satellite_scene := preload("res://scenes/satellite.tscn")

func _ready() -> void:
	_update_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_layout()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var bodies: Array = []
	if planet != null and planet.has_method("get_body_data"):
		bodies.append(planet.call("get_body_data"))
	if satellites != null:
		for child in satellites.get_children():
			if child.has_method("get_body_data"):
				bodies.append(child.call("get_body_data"))
	player.set_gravity_bodies(bodies)

func _update_layout() -> void:
	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var surface_height = viewport_size.y * surface_fraction
	var radius = viewport_size.x * planet_radius_scale
	var center = Vector2(viewport_size.x * 0.5, viewport_size.y - surface_height + radius)

	planet.set_planet(center, radius)
	_spawn_satellites(center, radius)
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

func _spawn_satellites(center: Vector2, radius: float) -> void:
	if satellites == null:
		return

	for child in satellites.get_children():
		child.queue_free()

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var count = max(satellite_count, 0)
	var min_size = min(satellite_radius_range.x, satellite_radius_range.y)
	var max_size = max(satellite_radius_range.x, satellite_radius_range.y)
	var min_speed = min(satellite_orbit_speed_range.x, satellite_orbit_speed_range.y)
	var max_speed = max(satellite_orbit_speed_range.x, satellite_orbit_speed_range.y)
	var jump_height = 0.0
	if player != null and player.gravity_strength > 0.0:
		jump_height = (player.jump_speed * player.jump_speed) / (2.0 * player.gravity_strength)
	var min_surface_gap = jump_height * 1.5
	var previous_orbit_radius = 0.0
	var previous_size = 0.0

	for i in range(count):
		var satellite = satellite_scene.instantiate()
		satellites.add_child(satellite)

		var size = rng.randf_range(min_size, max_size)
		var desired_orbit_radius = radius + satellite_orbit_offset + float(i) * satellite_orbit_gap
		var orbit_radius = desired_orbit_radius
		if i == 0:
			var min_orbit_radius = radius + size + min_surface_gap
			orbit_radius = max(orbit_radius, min_orbit_radius)
		else:
			var min_orbit_radius = previous_orbit_radius + previous_size + size + min_surface_gap
			orbit_radius = max(orbit_radius, min_orbit_radius)
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(min_speed, max_speed)
		if rng.randf() < 0.5:
			speed = -speed
		var is_primary = i == 0

		if satellite.has_method("setup"):
			satellite.call("setup", center, orbit_radius, angle, speed, size, is_primary)

		previous_orbit_radius = orbit_radius
		previous_size = size
