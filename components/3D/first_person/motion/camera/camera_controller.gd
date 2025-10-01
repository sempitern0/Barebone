@icon("res://components/3D/first_person/motion/camera/camera_controller.svg")
class_name CameraController extends Node3D

@export var actor: FirstPersonController
@export var camera_pivot: Node3D
@export var camera: Camera3D
@export var mouse_capture: MouseCaptureComponent
## 0 Means the rotation on the Y-axis is not limited
@export_range(0, 360.0, 0.01, "radians_as_degrees") var camera_vertical_limit: float = deg_to_rad(89.0)
## 0 Means the rotation on the X-axis is not limited
@export_range(0, 360.0, 0.01, "radians_as_degrees") var camera_horizontal_limit: float = 0.0
@export_category("Fov")
@export_range(1.0, 179.0, 0.01) var base_fov: float = 75.0
@export_range(0, 10.0, 0.01) var fov_smooth_factor: float = 1.2 
@export var fov_lerp_speed: float = 6.0

var current_vertical_limit: float:
	set(value):
		current_vertical_limit = clampf(value, 0.0, TAU)

var current_horizontal_limit: float:
	set(value):
		current_horizontal_limit = clampf(value, 0.0, TAU)


var locked: bool = false:
	set(value):
		set_physics_process(not locked)
		set_process_unhandled_input(not locked)

var current_camera_fov: float ## Change this variable from the outside to change the fov smoothly in physic_process


func _ready() -> void:
	if actor == null:
		actor = get_parent_node_3d()
	
	assert(actor is FirstPersonController, "CameraController: the actor variable does not reference a FirstPersonController, this camera controller needs a valid reference.")
	
	current_horizontal_limit = camera_horizontal_limit
	current_vertical_limit = camera_vertical_limit
	
	if camera:
		var accessibility_settings_fov = SettingsManager.get_accessibility_section(GameSettings.CameraFovSetting)
		
		if accessibility_settings_fov:
			base_fov = accessibility_settings_fov
		
		camera.fov = base_fov
		current_camera_fov = camera.fov
	
	set_physics_process(not locked)
	set_process_unhandled_input(not locked)
	
	SettingsManager.updated_setting_section.connect(on_setting_section_updated)


func _physics_process(delta: float) -> void:
	rotate_camera_with_mouse()
	#rotate_camera_with_gamepad(delta)
	fov_adjustment(delta, current_camera_fov)

	
func rotate_camera_with_mouse() -> void:
	if mouse_capture.mouse_input.is_zero_approx():
		return
	
	actor.rotate_y(mouse_capture.twist_input)
	camera_pivot.rotate_x(mouse_capture.pitch_input)
	
	actor.rotation.y = limit_horizontal_rotation(actor.rotation.y)
	camera_pivot.rotation.x = limit_vertical_rotation(camera_pivot.rotation.x)


#func rotate_camera_with_gamepad(_delta: float) -> void:
	#var joystick_motion: Vector2 = actor.motion_input.input_right_motion_as_vector
	#
	#if joystick_motion.length() >= 0.2:
		#var controller_sensitivity: float = controller_joystick_sensitivity / 100 # 5 becomes 0.05
		#var twist_input: float = -joystick_motion.x * controller_sensitivity ## Giro
		#var pitch_input: float = -joystick_motion.y * controller_sensitivity ## Cabeceo
		#
		#actor.rotate_y(twist_input)
		#camera_pivot.rotate_x(pitch_input)
		#
		#actor.rotation_degrees.y = limit_horizontal_rotation(actor.rotation_degrees.y)
		#camera_pivot.rotation_degrees.x = limit_vertical_rotation(camera_pivot.rotation_degrees.x)


func fov_adjustment(delta: float, new_fov: float) -> void:
	if camera and new_fov != camera.fov:
		var velocity: float = maxf(0.5, actor.velocity.length())
		var target_fov = new_fov + fov_smooth_factor * velocity

		camera.fov = lerp(camera.fov, target_fov, delta * fov_lerp_speed)

	
func lock() -> void:
	locked = true


func unlock() -> void:
	locked = false


func limit_vertical_rotation(angle: float) -> float:
	if current_vertical_limit > 0:
		return clampf(angle, -current_vertical_limit, current_vertical_limit)
	
	return angle


func limit_horizontal_rotation(angle: float) -> float:
	if current_horizontal_limit > 0:
		return clampf(angle, -current_horizontal_limit, current_horizontal_limit)
	
	return angle


#region Camera rotation
func change_horizontal_rotation_limit(new_rotation: int) -> void:
	current_horizontal_limit = new_rotation
	
func change_vertical_rotation_limit(new_rotation: int) -> void:
	current_vertical_limit = new_rotation
	
func return_to_original_horizontal_rotation_limit() -> void:
	current_horizontal_limit = camera_horizontal_limit
	
func return_to_original_vertical_rotation_limit() -> void:
	current_vertical_limit = camera_vertical_limit
#endregion

func on_setting_section_updated(_section: String, key: String, value: Variant) -> void:
		match key:
			GameSettings.CameraFovSetting:
				current_camera_fov = value
