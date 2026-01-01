extends Node2D

@export var orbit_radius: float = 200.0
@export var orbit_speed: float = 0.6
@export var radius: float = 36.0
@export var color: Color = Color(0.65, 0.7, 0.82)

var orbit_center: Vector2 = Vector2.ZERO
var orbit_angle: float = 0.0

func _ready() -> void:
	queue_redraw()

func setup(center_position: Vector2, orbit_distance: float, start_angle: float, speed: float, size: float, primary_visible: bool) -> void:
	orbit_center = center_position
	orbit_radius = orbit_distance
	orbit_angle = start_angle
	orbit_speed = speed
	radius = size
	z_index = 1 if primary_visible else -1
	global_position = orbit_center + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
	queue_redraw()

func set_orbit_center(center_position: Vector2) -> void:
	orbit_center = center_position

func _physics_process(delta: float) -> void:
	orbit_angle = fmod(orbit_angle + orbit_speed * delta, TAU)
	global_position = orbit_center + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius

func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(Vector2.ZERO, radius, color)

func get_body_data() -> Dictionary:
	return {
		"id": get_instance_id(),
		"center": global_position,
		"radius": radius
	}
