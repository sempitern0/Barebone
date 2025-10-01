class_name WeaponTilt extends WeaponMotion

@export var configuration: WeaponTiltResource

var target_tilt_rotation = Vector3.ZERO
var target_push_position = Vector3.ZERO


func _physics_process(delta):
	if actor.motion_input.input_direction.y < 0:
		target_push_position.z = configuration.hip_push_forward * actor.motion_input.input_direction.y
	else:
		target_push_position.z = configuration.hip_push_backward * actor.motion_input.input_direction.y

	target_tilt_rotation.z = configuration.tilt_horizontal * actor.motion_input.input_direction.x
	target_tilt_rotation.x = configuration.tilt_vertical * -actor.motion_input.input_direction.y
	
	if configuration.inverted:
		target_tilt_rotation.z *= -1
		target_tilt_rotation.x *= -1

	position.z = lerp(position.z, target_push_position.z, delta * configuration.push_smoothing)
	rotation.x = lerp_angle(rotation.x, target_tilt_rotation.x, delta * configuration.tilt_smoothing)
	rotation.z = lerp_angle(rotation.z, target_tilt_rotation.z, delta * configuration.tilt_smoothing)
