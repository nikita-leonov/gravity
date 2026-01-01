extends Node2D

@export var move_accel: float = 900.0
@export var max_move_speed: float = 260.0
@export var jump_speed: float = 420.0
@export var gravity_strength: float = 900.0
@export var radius: float = 16.0
@export var max_target_angle: float = 0.7
@export var aligned_jump_angle: float = 0.35
@export var aligned_jump_boost: float = 1.6
@export var jump_assist_duration: float = 0.45
@export var jump_assist_bias: float = 220.0
@export var surface_snap_distance: float = 6.0

var planet_center: Vector2 = Vector2.ZERO
var planet_radius: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var grounded := false
var gravity_bodies: Array = []
var jump_assist_target: Vector2 = Vector2.ZERO
var jump_assist_timer: float = 0.0
var gravity_lock_id: int = 0
var current_gravity_id: int = 0
var last_gravity_id: int = 0
var last_gravity_center: Vector2 = Vector2.ZERO
var last_body_velocity: Vector2 = Vector2.ZERO
var jump_in_progress := false

func _ready() -> void:
	_set_visual_size()

func set_gravity_bodies(bodies: Array) -> void:
	gravity_bodies = bodies

func _physics_process(delta: float) -> void:
	if gravity_bodies.is_empty():
		return

	if jump_assist_timer > 0.0:
		jump_assist_timer = max(jump_assist_timer - delta, 0.0)

	_select_gravity_target()
	if planet_radius <= 0.0:
		return

	_update_body_motion(delta)

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
		var jump_solution = _get_jump_solution(direction_to_center)
		var jump_direction = jump_solution["direction"] as Vector2
		var jump_multiplier = 1.0
		gravity_lock_id = 0
		if jump_solution["aligned"]:
			jump_multiplier = aligned_jump_boost
			jump_assist_target = jump_solution["target_center"] as Vector2
			jump_assist_timer = jump_assist_duration
			gravity_lock_id = jump_solution["target_id"] as int
		velocity += jump_direction * jump_speed * jump_multiplier
		grounded = false
		jump_in_progress = true

	global_position += velocity * delta
	_apply_surface_constraints()
	rotation = tangent.angle()
	last_gravity_center = planet_center
	last_gravity_id = current_gravity_id

func _select_gravity_target() -> void:
	if gravity_lock_id != 0:
		for body in gravity_bodies:
			if not body.has("id") or not body.has("center") or not body.has("radius"):
				continue
			if body["id"] == gravity_lock_id:
				planet_center = body["center"]
				planet_radius = body["radius"]
				current_gravity_id = body["id"]
				gravity_lock_id = 0
				return
		gravity_lock_id = 0

	if current_gravity_id != 0:
		var found_current = false
		for body in gravity_bodies:
			if not body.has("id") or not body.has("center") or not body.has("radius"):
				continue
			if body["id"] == current_gravity_id:
				planet_center = body["center"]
				planet_radius = body["radius"]
				found_current = true
				break
		if found_current:
			if not jump_in_progress:
				return
		else:
			current_gravity_id = 0

	if current_gravity_id != 0 and not jump_in_progress:
		return

	var best_center = planet_center
	var best_radius = planet_radius
	var best_distance = INF
	var best_id = current_gravity_id

	for body in gravity_bodies:
		if not body.has("id") or not body.has("center") or not body.has("radius"):
			continue
		var center = body["center"]
		var body_radius = body["radius"]
		var distance = (global_position - center).length() - (body_radius + radius)
		if jump_assist_timer > 0.0 and center == jump_assist_target:
			var bias_scale = 0.0
			if jump_assist_duration > 0.0:
				bias_scale = jump_assist_timer / jump_assist_duration
			distance -= jump_assist_bias * bias_scale
		if distance < best_distance:
			best_distance = distance
			best_center = center
			best_radius = body_radius
			best_id = body["id"]

	planet_center = best_center
	planet_radius = best_radius
	current_gravity_id = best_id

func _get_jump_solution(direction_to_center: Vector2) -> Dictionary:
	var jump_direction = -direction_to_center
	var jump_reference = jump_direction
	var best_dot = cos(max_target_angle)
	var best_alignment = -1.0
	var target_center = Vector2.ZERO
	var target_id = 0
	var has_target = false

	for body in gravity_bodies:
		if not body.has("id") or not body.has("center") or not body.has("radius"):
			continue
		var center = body["center"]
		if center == planet_center:
			continue
		var to_body = (center - global_position)
		if to_body.length() <= 0.0:
			continue
		var candidate_direction = to_body.normalized()
		var alignment = candidate_direction.dot(jump_reference)
		if alignment > best_dot:
			best_dot = alignment
			best_alignment = alignment
			jump_direction = candidate_direction
			target_center = center
			target_id = body["id"]
			has_target = true

	var aligned = false
	if has_target:
		if best_alignment < 0.0:
			best_alignment = jump_direction.dot(jump_reference)
		aligned = best_alignment >= cos(aligned_jump_angle)

	return {
		"direction": jump_direction,
		"aligned": aligned,
		"target_center": target_center,
		"target_id": target_id
	}

func _apply_surface_constraints() -> void:
	var desired_radius = planet_radius + radius
	var offset = global_position - planet_center
	var distance = offset.length()
	if distance <= 0.0:
		return

	var normal = offset / distance
	var radial_velocity = velocity.dot(normal)
	grounded = false
	if distance <= desired_radius + surface_snap_distance and radial_velocity <= 0.0:
		global_position = planet_center + normal * desired_radius
		velocity -= normal * radial_velocity
		grounded = true
		gravity_lock_id = current_gravity_id
		jump_in_progress = false

func _update_body_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	if grounded and current_gravity_id == last_gravity_id and last_gravity_center != Vector2.ZERO:
		var center_delta = planet_center - last_gravity_center
		if center_delta != Vector2.ZERO:
			var body_velocity = center_delta / delta
			global_position += center_delta
			velocity += body_velocity - last_body_velocity
			last_body_velocity = body_velocity
		else:
			last_body_velocity = Vector2.ZERO
	else:
		last_body_velocity = Vector2.ZERO

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
