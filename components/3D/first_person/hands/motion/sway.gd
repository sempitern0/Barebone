class_name WeaponSway extends WeaponMotion

@export var configuration: WeaponSwayResource

var original_rotation: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var relative_input: Vector2 = Vector2.ZERO


func _ready():
	original_rotation = rotation_degrees


func _physics_process(delta: float) -> void:
	relative_input = actor.mouse_capture.mouse_input
	
	var joystick_motion: Vector2 = actor.motion_input.input_right_motion_as_vector
	## Support for right joystick, if no gamepad is connected this value is not changed
	if joystick_motion.length() >= 0.2:
		relative_input = joystick_motion
		#var controller_sensitivity: float = controller_joystick_sensitivity / 100 # 5 becomes 0.05
		#var twist_input: float = -joystick_motion.x * controller_sensitivity ## Giro
		#var pitch_input: float = -joystick_motion.y * controller_sensitivity ## Cabeceo
		#
	
	target_rotation = Vector3(
	original_rotation.x + relative_input.y * configuration.base_multiplier * clampf(1.0, 0.1, 1.0), 
	original_rotation.y + - relative_input.x * configuration.base_multiplier * clampf(1.0, 0.1, 1.0), 
	original_rotation.z)

	rotation_degrees = rotation_degrees.lerp(target_rotation, delta * configuration.smoothing)
	relative_input = Vector2.ZERO
