class_name WeaponImpulse extends WeaponMotion

@export var configuration: WeaponImpulseResource

var current_kick: Vector3 = Vector3.ZERO
var current_rotation: Vector3 = Vector3.ZERO


func _physics_process(delta):
	var current_state: MachineState = actor.motion_state_machine.current_state
	var previous_state: MachineState = actor.motion_state_machine.last_state()
	var next_to_previous_state: MachineState = actor.motion_state_machine.next_to_last_state()
	
	current_kick = current_kick.lerp(Vector3.ZERO, delta * configuration.jump_kick_power)
	current_rotation = current_rotation.lerp(Vector3.ZERO, delta * configuration.jump_rotation_power)

	position = lerp(position, current_kick, delta * configuration.jump_kick_power)
	rotation = lerp(rotation, current_rotation, delta * configuration.jump_rotation_power)

	if current_state is JumpState:
		if previous_state is RunState:
			apply_jump_kick(configuration.multiplier_on_jump_after_run)
		else:
			apply_jump_kick(configuration.multiplier_on_jump)
	
	elif previous_state is AirState and current_state is GroundState:
		if next_to_previous_state is RunState:
			apply_land_kick(configuration.multiplier_on_land_after_run)
		else:
			apply_land_kick(configuration.multiplier_on_land)
		
	elif current_state is CrouchState \
		or (previous_state is CrouchState \
		and (current_state is IdleState or current_state is WalkState)):
		apply_jump_kick(configuration.multiplier_on_crouch)
		
	
func apply_jump_kick(multiplier):
	current_rotation = Vector3(configuration.jump_rotation.x * multiplier, configuration.jump_rotation.y * multiplier, 0.0)
	current_kick = Vector3(0.0, configuration.jump_kick * multiplier, 0.0)
	
	if configuration.camera:
		current_rotation.x *= -1


func apply_land_kick(multiplier):
	current_rotation = Vector3(-configuration.jump_rotation.x * multiplier, configuration.jump_rotation.y * multiplier, 0.0)
	current_kick = Vector3(0.0, -configuration.jump_kick * multiplier, 0.0)
	
	if configuration.camera:
		current_rotation.x *= -1
