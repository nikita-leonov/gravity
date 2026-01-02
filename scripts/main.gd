extends Node2D

@export var surface_fraction: float = 0.33
@export var sun_radius_scale: float = 0.9
@export var obstacle_count: int = 6
@export var obstacle_size_range: Vector2 = Vector2(18.0, 34.0)
@export var planet_count: int = 3
@export var planet_orbit_offset: float = 200.0
@export var planet_orbit_gap: float = 160.0
@export var planet_radius_range: Vector2 = Vector2(80.0, 140.0)
@export var planet_orbit_speed_range: Vector2 = Vector2(0.1, 0.35)
@export var satellites_per_planet: int = 2
@export var satellite_orbit_offset: float = 110.0
@export var satellite_orbit_gap: float = 90.0
@export var satellite_radius_range: Vector2 = Vector2(36.0, 70.0)
@export var satellite_orbit_speed_range: Vector2 = Vector2(0.4, 0.9)

@onready var gravity_objects = $GravityObjects
@onready var sun = $GravityObjects/Sun
@onready var player = $Player
@onready var obstacles = $Obstacles

var obstacle_scene := preload("res://scenes/obstacle.tscn")
var gravity_object_scene := preload("res://scenes/gravity_object.tscn")

func _ready() -> void:
	_update_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_layout()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var bodies: Array = []
	for body in get_tree().get_nodes_in_group("gravity_object"):
		if body.has_method("get_body_data"):
			bodies.append(body.call("get_body_data"))
	player.set_gravity_bodies(bodies)

func _update_layout() -> void:
	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var surface_height = viewport_size.y * surface_fraction
	var radius = viewport_size.x * sun_radius_scale
	var center = Vector2(viewport_size.x * 0.5, viewport_size.y - surface_height + radius)

	sun.set_body(center, radius)
	_clear_orbiting_objects()
	_spawn_planets()
	_spawn_obstacles(center, radius)

	var spawn_direction = Vector2(0.0, -1.0)
	player.global_position = center + spawn_direction * (radius + player.radius)

func _clear_orbiting_objects() -> void:
	if gravity_objects == null:
		return
	for child in gravity_objects.get_children():
		if child == sun:
			continue
		child.queue_free()

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

func _spawn_planets() -> void:
	if gravity_objects == null:
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var count = max(planet_count, 0)
	var min_size = min(planet_radius_range.x, planet_radius_range.y)
	var max_size = max(planet_radius_range.x, planet_radius_range.y)
	var min_speed = min(planet_orbit_speed_range.x, planet_orbit_speed_range.y)
	var max_speed = max(planet_orbit_speed_range.x, planet_orbit_speed_range.y)
	var min_surface_gap = _get_min_surface_gap()
	var obstacle_buffer = _get_obstacle_buffer()
	var max_satellite_extent = _get_max_satellite_extent()
	var previous_orbit_radius = 0.0
	var previous_system_extent = 0.0

	for i in range(count):
		var planet = gravity_object_scene.instantiate()
		gravity_objects.add_child(planet)
		planet.z_index = 1

		var size = rng.randf_range(min_size, max_size)
		var system_extent = max(size, max_satellite_extent)
		var desired_orbit_radius = sun.radius + planet_orbit_offset + float(i) * planet_orbit_gap
		var orbit_radius = desired_orbit_radius
		if i == 0:
			var min_orbit_radius = sun.radius + obstacle_buffer + system_extent + min_surface_gap
			orbit_radius = max(orbit_radius, min_orbit_radius)
		else:
			var min_orbit_radius = previous_orbit_radius + previous_system_extent + system_extent + min_surface_gap
			orbit_radius = max(orbit_radius, min_orbit_radius)
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(min_speed, max_speed)
		if rng.randf() < 0.5:
			speed = -speed

		if planet.has_method("setup_orbit"):
			planet.call("setup_orbit", sun, orbit_radius, angle, speed, size)
		_spawn_satellites_for_planet(planet, rng)

		previous_orbit_radius = orbit_radius
		previous_system_extent = system_extent

func _spawn_satellites_for_planet(planet: Node2D, rng: RandomNumberGenerator) -> void:
	if gravity_objects == null:
		return

	var count = max(satellites_per_planet, 0)
	var min_size = min(satellite_radius_range.x, satellite_radius_range.y)
	var max_size = max(satellite_radius_range.x, satellite_radius_range.y)
	var min_speed = min(satellite_orbit_speed_range.x, satellite_orbit_speed_range.y)
	var max_speed = max(satellite_orbit_speed_range.x, satellite_orbit_speed_range.y)
	var min_surface_gap = _get_min_surface_gap()
	var previous_orbit_radius = 0.0
	var previous_size = 0.0

	for i in range(count):
		var satellite = gravity_object_scene.instantiate()
		gravity_objects.add_child(satellite)
		satellite.z_index = 2

		var size = rng.randf_range(min_size, max_size)
		var desired_orbit_radius = planet.radius + satellite_orbit_offset + float(i) * satellite_orbit_gap
		var orbit_radius = desired_orbit_radius
		if i == 0:
			var min_orbit_radius = planet.radius + size + min_surface_gap
			orbit_radius = max(orbit_radius, min_orbit_radius)
		else:
			var min_orbit_radius = previous_orbit_radius + previous_size + size + min_surface_gap
			orbit_radius = max(orbit_radius, min_orbit_radius)
		var angle = rng.randf_range(0.0, TAU)
		var speed = rng.randf_range(min_speed, max_speed)
		if rng.randf() < 0.5:
			speed = -speed

		if satellite.has_method("setup_orbit"):
			satellite.call("setup_orbit", planet, orbit_radius, angle, speed, size)

		previous_orbit_radius = orbit_radius
		previous_size = size

func _get_min_surface_gap() -> float:
	var jump_height = 0.0
	if player != null and player.gravity_strength > 0.0:
		jump_height = (player.jump_speed * player.jump_speed) / (2.0 * player.gravity_strength)
	return jump_height * 1.5

func _get_obstacle_buffer() -> float:
	var max_size = max(obstacle_size_range.x, obstacle_size_range.y)
	return max_size

func _get_max_satellite_extent() -> float:
	var count = max(satellites_per_planet, 0)
	if count == 0:
		return 0.0
	var max_satellite_size = max(satellite_radius_range.x, satellite_radius_range.y)
	var gap = max(satellite_orbit_gap, 0.0)
	var max_orbit_radius = satellite_orbit_offset + float(count - 1) * gap
	return max_orbit_radius + max_satellite_size
