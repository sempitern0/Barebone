@icon("res://components/3D/first_person/motion/effects/head.svg")
class_name MotionTilt extends Node3D

@export var actor: FirstPersonController
@export var camera: Camera3D
@export var enabled: bool = true:
	set(value):
		enabled = value
		set_physics_process(enabled and (front_swing or side_swing))

@export var front_swing: bool = true:
	set(value):
		front_swing = value
		set_physics_process(enabled and (front_swing or side_swing))
		
@export var side_swing: bool = true:
	set(value):
		side_swing = value
		set_physics_process(enabled and (front_swing or side_swing))
@export var side_on_diagonal: bool = false
@export_range(0, 360.0, 0.01, "radians_as_degrees") var swing_rotation_degrees: float = deg_to_rad(1.5)
@export_range(0, 360.0, 0.01, "radians_as_degrees") var swing_side_rotation_degrees: float = deg_to_rad(1.5)
@export var swing_lerp_factor: float = 5.0
@export var swing_lerp_recovery_factor: float = 7.5


func _ready() -> void:
	set_physics_process(enabled and (front_swing or side_swing))
	

func _physics_process(delta: float) -> void:
	var direction = actor.motion_input.input_direction
	
	if side_swing and \
		(direction in OmniKitVectorHelper.horizontal_directions_v2 or (side_on_diagonal and OmniKitVectorHelper.is_diagonal_direction_v2(direction))):
		camera.rotation.z = lerp_angle(
			camera.rotation.z, 
			-sign(direction.x) * swing_side_rotation_degrees, 
			swing_lerp_factor * delta
			)
	elif front_swing and direction in OmniKitVectorHelper.vertical_directions_v2:
		camera.rotation.x = lerp_angle(
			camera.rotation.x, 
			sign(direction.y) * swing_rotation_degrees, 
			swing_lerp_factor * delta
			)
	else:
		camera.rotation.z = lerp_angle(
			camera.rotation.z, 0.0,
			 swing_lerp_recovery_factor * delta
			)
			
		camera.rotation.x = lerp_angle(
			camera.rotation.x, 0.0,
			 swing_lerp_recovery_factor * delta
			)

func enable() -> void:
	enabled = true
	

func disable() -> void:
	enabled = false
