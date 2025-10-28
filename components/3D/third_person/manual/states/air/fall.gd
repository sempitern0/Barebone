class_name ThirdPersonFallState extends ThirdPersonAirState


func physics_update(delta: float):
	super.physics_update(delta)
	
	if maximum_fall_velocity > 0:
		limit_fall_velocity()
		
	if actor.is_on_floor():
		if actor.motion_input.input_direction.is_zero_approx():
			FSM.change_state_to(ThirdPersonIdleState)
		else:
			FSM.change_state_to(ThirdPersonWalkState)

	
	actor.move_and_slide()
