class_name ThirdPersonIdleState extends ThirdPersonGroundState


func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if actor.is_on_floor():
		decelerate(delta)
		
		if not actor.motion_input.input_direction.is_zero_approx():
			FSM.change_state_to(ThirdPersonWalkState)
		
	actor.move_and_slide()
