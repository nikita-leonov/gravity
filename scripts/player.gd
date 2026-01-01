extends Node2D

@export var move_accel: float = 900.0
@export var max_move_speed: float = 260.0
@export var jump_speed: float = 420.0
@export var gravity_strength: float = 900.0
@export var radius: float = 16.0
@export var max_target_angle: float = 0.7

var planet_center: Vector2 = Vector2.ZERO
var planet_radius: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var grounded := false
var gravity_bodies: Array = []

func _ready() -> void:
	_set_visual_size()

func set_gravity_bodies(bodies: Array) -> void:
	gravity_bodies = bodies

func _physics_process(delta: float) -> void:
	if gravity_bodies.is_empty():
		return

	_select_gravity_target()
	if planet_radius <= 0.0:
		return

	var direction_to_center = (planet_center - global_position).normalized()
	var tangent = Vector2(-direction_to_center.y, direction_to_center.x)
	var input_axis = Input.get_axis("ui_right", "ui_left")

	if input_axis != 0.0:
		velocity += tangent * input_axis * move_accel * delta
		var tangential_speed = velocity.dot(tangent)
		if abs(tangential_speed) > max_move_speed:
			velocity -= tangent * (tangential_speed - sign(tangential_speed) * max_move_speed)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_accel * 0.6 * delta)

	velocity += direction_to_center * gravity_strength * delta

	if grounded and Input.is_action_just_pressed("ui_accept"):
		var jump_direction = _get_jump_direction(direction_to_center)
		velocity += jump_direction * jump_speed
		grounded = false

	global_position += velocity * delta
	_apply_surface_constraints()
	rotation = tangent.angle()

func _select_gravity_target() -> void:
	var best_center = planet_center
	var best_radius = planet_radius
	var best_distance = INF

	for body in gravity_bodies:
		if not body.has("center") or not body.has("radius"):
			continue
		var center = body["center"]
		var body_radius = body["radius"]
		var distance = (global_position - center).length() - (body_radius + radius)
		if distance < best_distance:
			best_distance = distance
			best_center = center
			best_radius = body_radius

	planet_center = best_center
	planet_radius = best_radius

func _get_jump_direction(direction_to_center: Vector2) -> Vector2:
	var jump_direction = -direction_to_center
	var best_dot = cos(max_target_angle)

	for body in gravity_bodies:
		if not body.has("center") or not body.has("radius"):
			continue
		var center = body["center"]
		var to_body = (center - global_position)
		if to_body.length() <= 0.0:
			continue
		var candidate_direction = to_body.normalized()
		var alignment = candidate_direction.dot(jump_direction)
		if alignment > best_dot:
			best_dot = alignment
			jump_direction = candidate_direction

	return jump_direction

func _apply_surface_constraints() -> void:
	var desired_radius = planet_radius + radius
	var offset = global_position - planet_center
	var distance = offset.length()
	if distance <= 0.0:
		return

	var normal = offset / distance
	grounded = false
	if distance < desired_radius:
		global_position = planet_center + normal * desired_radius
		var radial_velocity = velocity.dot(normal)
		if radial_velocity < 0.0:
			velocity -= normal * radial_velocity
		grounded = true

func _set_visual_size() -> void:
	var polygon = $Polygon2D
	if polygon == null:
		return
	polygon.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
