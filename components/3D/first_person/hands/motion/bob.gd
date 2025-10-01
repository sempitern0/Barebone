class_name WeaponBob extends WeaponMotion

@export var configuration: WeaponBobResource:
	set(new_configuration):
		configuration = new_configuration
		apply_configuration_values()

var weapon_noise_offset = Vector3.ZERO
var weapon_noise = Vector3.ZERO

var final_frequency: float = 0.0
var final_amplitude: float = 0.0

var headbob_index: float = 0.0
var headbob_vector = Vector2.ZERO

var arm_multiplier: float = 1.0

var original_position: Vector3 = Vector3.ZERO

var current_headbob_intensity: float 
var current_headbob_index_lerp_speed: float
var current_target_frequency: float
var current_target_amplitude: float
var current_target_lerp_speed: float


func _ready() -> void:
	original_position = position
	apply_configuration_values()


func _physics_process(delta: float) -> void:
	var speed: float = actor.get_ground_speed()

	if actor.is_grounded and snappedf(speed, 0.01) > 0.2:
		headbob_index += current_headbob_index_lerp_speed * delta

		headbob_vector.x = sin(headbob_index / 2)
		headbob_vector.y = sin(headbob_index)
		
		position.x = lerp(position.x, headbob_vector.x * current_headbob_intensity, delta * current_headbob_index_lerp_speed)
		position.y = lerp(position.y, headbob_vector.y * (current_headbob_intensity * 2), delta * current_headbob_index_lerp_speed)
		
		final_frequency = lerpf(final_frequency, current_target_frequency * arm_multiplier, delta * current_target_lerp_speed)
		final_amplitude = lerpf(final_amplitude, current_target_amplitude * arm_multiplier, delta * current_target_lerp_speed)

		var weapon_scroll_offset: float = delta * final_frequency
		
		weapon_noise_offset += Vector3.ONE * weapon_scroll_offset
	
		weapon_noise.x = configuration.noise.get_noise_2d(weapon_noise_offset.x, 0.0)
		weapon_noise.y = configuration.noise.get_noise_2d(weapon_noise_offset.y, 1.0)
		weapon_noise.z = configuration.noise.get_noise_2d(weapon_noise_offset.z, 2.0)

		weapon_noise *= final_amplitude
		
		rotation = weapon_noise
	else:
		position.y = lerp(position.y, original_position.y, current_headbob_index_lerp_speed * delta)
		position.x = lerp(position.x, original_position.x, current_headbob_index_lerp_speed * delta)


func apply_configuration_values() -> void:
	if configuration:
		current_headbob_intensity = configuration.headbob_intensity
		current_headbob_index_lerp_speed = configuration.headbob_lerp_speed
		current_target_frequency = configuration.target_frequency
		current_target_amplitude = configuration.target_amplitude
		current_target_lerp_speed = configuration.target_lerp_speed
