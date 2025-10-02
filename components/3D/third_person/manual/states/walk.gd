class_name ThirdPersonWalkState extends ThirdPersonGroundState

var last_move_direction: Vector3 = Vector3.BACK


func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if actor.motion_input.input_direction.is_zero_approx():
		FSM.change_state_to(ThirdPersonIdleState)
		return
		
	var forward: Vector3 = actor.camera.global_basis.z
	var right: Vector3 = actor.camera.global_basis.x
	var move_direction = forward * actor.motion_input.input_direction.y + right * actor.motion_input.input_direction.x
	move_direction.y = 0
	move_direction = move_direction.normalized()
	
	accelerate(move_direction, delta)
		
	if move_direction.length() > 0.2:
		last_move_direction = move_direction
	
	rotate_skin(last_move_direction)
	
	actor.move_and_slide()
