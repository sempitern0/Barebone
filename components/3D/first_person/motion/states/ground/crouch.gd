class_name CrouchState extends GroundState

@export var crouch_animation_time: float = 0.2

	
func enter() -> void:
	super.enter()
	actor.body_shape.disabled = true
	actor.crouch_shape.disabled = false
	
	crouch_animation(actor.head_crouch_height, crouch_animation_time)


func exit(next: MachineState) -> void:
	super.exit(next)
	
	actor.body_shape.disabled = false
	actor.crouch_shape.disabled = true
	
	crouch_animation(actor.head_stand_height, crouch_animation_time)


func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if not actor.ceil_detector.is_colliding() and not OmniKitInputHelper.action_pressed_and_exists(InputControls.CrouchAction):
		if actor.motion_input.input_direction.is_zero_approx():
			FSM.change_state_to(IdleState)
		else:
			FSM.change_state_to(WalkState)
		
		return
		
	accelerate(delta)
	
	stair_step_up()
	actor.move_and_slide()
	stair_step_down()
	
	#actor.footsteps_manager.footstep(0.4)
