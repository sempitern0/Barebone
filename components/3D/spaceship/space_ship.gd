class_name Spaceship3D extends CharacterBody3D

@export var camera: Camera3D
@export var ship_skin: Node3D

@export var base_fov: float = 70.0
@export var max_fov: float = 95.0
@export var fov_lerp_speed: float = 3.5
@export var max_speed: float = 20.0
@export var max_backward_speed: float = 10.0
@export var acceleration_forward: float = 6.0
@export var acceleration_backward: float = 4.0
@export var decceleration: float = 3.0
@export_range(0.0, 270.0, 0.01, "radians_as_degrees") var rotation_speed: float = deg_to_rad(60)
@export_range(0.0, 1.0, 0.01) var drag_speed: float = 0.02


var current_speed: float = 0.0
var speed_ratio: float = 0.0
var drift_direction: Vector3 = Vector3.FORWARD
var direction_input: Vector3 = Vector3.ZERO
var target_fov: float = base_fov


func _physics_process(delta: float) -> void:
	rotate_ship(delta)

	if Input.is_action_just_pressed(InputControls.RunAction):
		drift_direction = -ship_skin.global_transform.basis.z
		
	if Input.is_action_pressed(InputControls.RunAction):
		drift(delta)
	else:
		move_forward(delta)
	
	update_camera_fov(delta)
	move_and_slide()


func rotate_ship(delta: float = get_physics_process_delta_time()) -> void:
	var mouse_relative: Vector2 = OmniKitWindowManager.screen_relative_mouse_position(get_viewport())

	var pitch: Quaternion = Quaternion(transform.basis.x, -mouse_relative.y * rotation_speed * delta)
	var yaw: Quaternion = Quaternion(Vector3.UP, -mouse_relative.x * rotation_speed * delta)
	var new_basis: Basis = Basis(yaw * pitch) * transform.basis
	transform.basis = new_basis.orthonormalized()

	var ship_yaw: Quaternion = Quaternion(Vector3.UP, -mouse_relative.x * rotation_speed / 2.0)
	var ship_pitch: Quaternion = Quaternion(Vector3.RIGHT, -mouse_relative.y * rotation_speed)
	var ship_roll: Quaternion  = Quaternion(Vector3.FORWARD, mouse_relative.x * rotation_speed)
	ship_skin.rotation = (ship_yaw * ship_pitch * ship_roll).get_euler()


func move_forward(delta: float = get_physics_process_delta_time()) -> void:
	var forward: Vector3 = -ship_skin.global_transform.basis.z.normalized()

	if OmniKitInputHelper.action_pressed_and_exists(InputControls.MoveForward):
		current_speed += acceleration_forward * delta
	elif OmniKitInputHelper.action_pressed_and_exists(InputControls.MoveBack):
		current_speed -= acceleration_backward * delta
	else:
		if current_speed > 0:
			current_speed = maxf(current_speed - decceleration * delta, 0.0)
		elif current_speed < 0:
			current_speed = minf(current_speed + decceleration * delta, 0.0)
		
		current_speed *= (1.0 - drag_speed * delta)

	current_speed = clampf(current_speed, -max_backward_speed, max_speed)
	velocity = forward * current_speed


func drift(delta: float = get_physics_process_delta_time()) -> void:
	var forward: Vector3 = -ship_skin.global_transform.basis.z.normalized()

	drift_direction = drift_direction.lerp(forward, 0.7 * delta)
	velocity = drift_direction.normalized() * current_speed


func update_camera_fov(delta: float = get_physics_process_delta_time()) -> void:
	speed_ratio = absf(current_speed) / max_speed
	target_fov = lerpf(base_fov, max_fov, speed_ratio)
	camera.fov = lerpf(camera.fov, target_fov, fov_lerp_speed * delta)
