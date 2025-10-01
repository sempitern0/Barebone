class_name WeaponRecoil extends WeaponMotion

@export var configuration: WeaponRecoilResource

var current_kick: Vector3 = Vector3.ZERO
var current_rotation: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	calculate_recoil(delta)


func calculate_recoil(delta):
	current_rotation = lerp(current_rotation, Vector3.ZERO, delta * configuration.rotation_recovery)
	rotation = lerp(rotation, current_rotation, delta * configuration.rotation_power)

	current_kick = lerp(current_kick, Vector3.ZERO, delta * configuration.kick_recovery)
	position = lerp(position, current_kick, delta * configuration.kick_power)
	

## Call this function when shooting a firearm weapon
func add():
	if is_enabled():
		current_rotation = Vector3(-configuration.vertical_recoil, randf_range(-configuration.horizontal_recoil, configuration.horizontal_recoil), 0.0)
		current_kick = Vector3(0.0, 0.0, -configuration.kick)
