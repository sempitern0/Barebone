class_name FallState extends AirState

@export var enable_limit_fall_velocity: bool = true
@export var edge_gap_auto_jump: float = 0.45
@export var coyote_time: bool = true
@export var coyote_time_frames = 20
@export var jump_input_buffer: bool = true
@export var jump_input_buffer_time_frames: int = 30
@export_range(0, 360.0, 0.01, "degrees") var fall_kick_strength: float = 2.0
@export var fall_kick_time: float = 0.07


var jump_requested: bool = false
var current_coyote_time_frames: int = 0:
	set(value):
		current_coyote_time_frames = maxi(0, value)
		
var current_jump_input_buffer_time_frames: int = 0:
	set(value):
		current_jump_input_buffer_time_frames = maxi(0, value)


func enter():
	super.enter()
	
	jump_requested = false
	current_coyote_time_frames = coyote_time_frames
	current_jump_input_buffer_time_frames = jump_input_buffer_time_frames
	
	#if FSM.last_state() is GroundState:
		#FSM.last_state().stair_stepping = false
	#
	#wall_run_start_cooldown_timer.start()
	
	#detect_dash()
	
	actor.velocity += actor.global_transform.basis.z * edge_gap_auto_jump
	actor.move_and_slide()
	
	
func exit(next: MachineState) -> void:
	if next is GroundState and actor.fall_kick:
		actor.fall_kick_effect.add(fall_kick_strength, fall_kick_time)


func physics_update(delta: float):
	super.physics_update(delta)
	
	jump_requested = actor.jump and OmniKitInputHelper.action_just_pressed_and_exists(InputControls.JumpAction)
	current_coyote_time_frames -= 1
	current_jump_input_buffer_time_frames -= 1
	
	if jump_requested and _coyote_time_is_active():
		FSM.change_state_to(JumpState)
		
	elif (not actor.was_grounded and actor.is_grounded) or actor.is_on_floor():
		if jump_requested and jump_input_buffer_is_active():
			FSM.change_state_to(JumpState)
		else:
			if actor.motion_input.input_direction.is_zero_approx():
				FSM.change_state_to(IdleState)
			else:
				FSM.change_state_to(WalkState)
			
	
	if enable_limit_fall_velocity:
		limit_fall_velocity()
		
	if (not actor.was_grounded and actor.is_grounded):
		if actor.motion_input.input_direction.is_zero_approx():
			FSM.change_state_to(IdleState)
		else:
			FSM.change_state_to(WalkState)

	actor.move_and_slide()

#region Detectors
func _coyote_time_is_active() -> bool:
	return coyote_time and current_coyote_time_frames > 0 and FSM.last_state() is GroundState
	
func jump_input_buffer_is_active() -> bool:
	return jump_input_buffer and current_jump_input_buffer_time_frames > 0
#endregion
