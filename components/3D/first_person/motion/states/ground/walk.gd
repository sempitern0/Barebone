class_name WalkState extends GroundState

	
func enter():
	super.enter()
	actor.velocity.y = 0


func physics_update(delta):
	super.physics_update(delta)
		
	if actor.motion_input.input_direction.is_zero_approx():
		FSM.change_state_to(IdleState)
	
	accelerate(delta)
	
	detect_jump()
	detect_run()
	detect_crouch()
	detect_dash()
	
	stair_step_up()
	actor.move_and_slide()
	stair_step_down()
	
	#actor.footsteps_manager.footstep(0.4)
