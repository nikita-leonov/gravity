extends Node2D

@export var radius: float = 60.0
@export var color: Color = Color(0.14, 0.16, 0.22)
@export var orbit_radius: float = 0.0
@export var orbit_speed: float = 0.0
@export var orbit_angle: float = 0.0

var orbit_parent: Node2D = null
var current_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("gravity_object")
	queue_redraw()

func set_body(center_position: Vector2, body_radius: float, body_color: Color = color) -> void:
	orbit_parent = null
	orbit_radius = 0.0
	orbit_speed = 0.0
	orbit_angle = 0.0
	radius = body_radius
	color = body_color
	global_position = center_position
	current_velocity = Vector2.ZERO
	queue_redraw()

func setup_orbit(parent_body: Node2D, orbit_distance: float, start_angle: float, speed: float, body_radius: float, body_color: Color = color) -> void:
	orbit_parent = parent_body
	orbit_radius = orbit_distance
	orbit_angle = start_angle
	orbit_speed = speed
	radius = body_radius
	color = body_color
	global_position = _get_orbit_center() + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
	current_velocity = Vector2.ZERO
	queue_redraw()

func _physics_process(delta: float) -> void:
	if orbit_parent == null or orbit_radius <= 0.0:
		current_velocity = Vector2.ZERO
		return

	var previous_position = global_position
	orbit_angle = fmod(orbit_angle + orbit_speed * delta, TAU)
	global_position = _get_orbit_center() + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
	if delta > 0.0:
		current_velocity = (global_position - previous_position) / delta
	else:
		current_velocity = Vector2.ZERO

func _get_orbit_center() -> Vector2:
	if orbit_parent != null:
		return orbit_parent.global_position
	return global_position

func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(Vector2.ZERO, radius, color)

func get_body_data() -> Dictionary:
	return {
		"id": get_instance_id(),
		"center": global_position,
		"radius": radius,
		"velocity": current_velocity
	}
