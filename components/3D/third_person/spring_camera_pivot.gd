## Setup Node3D(SpringCameraPivot) -> SpringArm3D -> Node3D(SpringRelativePosition)
## Camera3D must be a sibling of SpringCameraPivot, as the camera actually follows the spring relative position for the smoothness effect
class_name ThirdPersonSpringCameraPivot extends Node3D

@export var spring_arm: SpringArm3D
@export var spring_relative_position: Node3D
@export var camera: Camera3D
@export var mouse_capture: MouseCaptureComponent
## Set to 0 to disable smoothness when the spring limit the camera movement with the collisions around the world
@export var camera_spring_smoothness: float = 6.0
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = deg_to_rad(-70.0)
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = deg_to_rad(5.0)
@export var zoom: bool = true
@export var zoom_out_step: float = 0.5
@export var zoom_in_step: float = 0.5
## The maximum spring length when zooming out camera
@export var max_spring_length_zoom_out: float = 15.0
## The maximum spring length when zooming in camera
@export var max_spring_length_zoom_in: float = 6.5

var enabled: bool = true:
	set(value):
		enabled = value
		set_physics_process(enabled and mouse_capture)

func _ready() -> void:	
	set_physics_process(enabled and mouse_capture)

	
func _physics_process(delta: float) -> void:
	if not mouse_capture.mouse_input.is_zero_approx():
		var new_pitch: float  = rotation.x + mouse_capture.pitch_input
		var new_twist: float  = rotation.y + mouse_capture.twist_input
		
		rotation.x = clampf(new_pitch, min_vertical_angle, max_vertical_angle)
		rotation.y = wrapf(new_twist, 0.0, TAU)
	
	if camera_spring_smoothness > 0:
		camera.position = lerp(camera.position, spring_relative_position.position, delta * camera_spring_smoothness)
	else:
		camera.position = spring_relative_position.position
	
	if zoom:
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
