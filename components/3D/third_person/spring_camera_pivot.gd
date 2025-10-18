## Setup:
## Node3D(SpringCameraPivot) -> SpringArm3D -> Node3D(SpringRelativePosition)
## Camera3D must be a sibling of SpringCameraPivot (the camera follows spring_relative_position)
class_name ThirdPersonSpringCameraPivot extends Node3D

@export var spring_arm: SpringArm3D
@export var spring_relative_position: Node3D
@export var camera: Camera3D
@export var mouse_capture: MouseCaptureComponent

@export var camera_spring_smoothness: float = 6.0
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = deg_to_rad(-70.0)
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = deg_to_rad(5.0)

@export_category("Zoom")
@export var zoom: bool = true
@export var max_spring_length_zoom_out: float = 15.0
@export var max_spring_length_zoom_in: float = 6.0
@export var zoom_out_step: float = 0.5
@export var zoom_in_step: float = 0.5
@export_category("Isometric mode")
@export var is_isometric_mode: bool = false
@export_range(-90.0, 90.0, 0.1, "radians_as_degrees") var isometric_angle: float = deg_to_rad(-35.264)
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var isometric_yaw_angle: float = deg_to_rad(45.0)
@export var isometric_distance: float = 10.0
@export var isometric_zoom_limit: float = 15.0
@export var allow_isometric_yaw_rotation: bool = true
@export var isometric_yaw_speed: float = 1.5
@export var camera_isometric_smoothness: float = 4.0

var enabled: bool = true:
	set(value):
		enabled = value
		set_physics_process(enabled and (mouse_capture or is_isometric_mode))


func _ready() -> void:
	set_physics_process(enabled and (mouse_capture or is_isometric_mode))


func _physics_process(delta: float) -> void:
	if is_isometric_mode:
		var target_rot_x: float = -absf(isometric_angle)
		var target_rot_y: float = isometric_yaw_angle
		
		rotation.x = lerp_angle(rotation.x, target_rot_x, delta * camera_isometric_smoothness)
		
		if allow_isometric_yaw_rotation:
			if not mouse_capture.mouse_input.is_zero_approx():
				rotation.y += mouse_capture.twist_input * isometric_yaw_speed
			else:
				if OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateLeft):
					rotation.y -= delta * isometric_yaw_speed
				elif OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateRight):
					rotation.y += delta * isometric_yaw_speed
		else:
			mouse_capture.mouse_input = Vector2.ZERO
			rotation.y = lerp_angle(rotation.y, target_rot_y, delta * camera_isometric_smoothness)

		spring_arm.spring_length = lerp(spring_arm.spring_length, isometric_distance, delta * camera_isometric_smoothness)
		spring_arm.spring_length = clampf(spring_arm.spring_length, 1.0, isometric_zoom_limit)
	
	else:
		if not mouse_capture.mouse_input.is_zero_approx():
			var new_pitch: float = rotation.x + mouse_capture.pitch_input
			var new_twist: float = rotation.y + mouse_capture.twist_input

			rotation.x = clampf(new_pitch, min_vertical_angle, max_vertical_angle)
			rotation.y = wrapf(new_twist, 0.0, TAU)

	if camera_spring_smoothness > 0:
		camera.position = lerp(camera.position, spring_relative_position.position, delta * camera_spring_smoothness)
	else:
		camera.position = spring_relative_position.position

	if zoom and not is_isometric_mode: 
		if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomInCamera):
			camera_zoom_in()
		elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomOutCamera):
			camera_zoom_out()


func camera_zoom_in() -> void:
	spring_arm.spring_length -= zoom_in_step
	spring_arm.spring_length = maxf(max_spring_length_zoom_in, spring_arm.spring_length)


func camera_zoom_out() -> void:
	spring_arm.spring_length += zoom_out_step
	spring_arm.spring_length = minf(max_spring_length_zoom_out, spring_arm.spring_length)
