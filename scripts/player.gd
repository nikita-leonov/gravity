extends Node2D

@export var move_accel: float = 900.0
@export var max_move_speed: float = 260.0
@export var jump_speed: float = 420.0
@export var gravity_strength: float = 900.0
@export var radius: float = 16.0

var planet_center: Vector2 = Vector2.ZERO
var planet_radius: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var grounded := false

func _ready() -> void:
	_set_visual_size()

func _physics_process(delta: float) -> void:
	if planet_radius <= 0.0:
		return

	var direction_to_center = (planet_center - global_position).normalized()
	var tangent = Vector2(-direction_to_center.y, direction_to_center.x)
	var input_axis = Input.get_axis("ui_left", "ui_right")

	if input_axis != 0.0:
		velocity += tangent * input_axis * move_accel * delta
		var tangential_speed = velocity.dot(tangent)
		if absf(tangential_speed) > max_move_speed:
			velocity -= tangent * (tangential_speed - signf(tangential_speed) * max_move_speed)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_accel * 0.6 * delta)

	velocity += direction_to_center * gravity_strength * delta

	if grounded and Input.is_action_just_pressed("ui_accept"):
		velocity += -direction_to_center * jump_speed
		grounded = false

	global_position += velocity * delta
	_apply_surface_constraints()
	rotation = tangent.angle()

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
