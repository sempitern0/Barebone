class_name RunState extends GroundState

@export var sprint_time: float = 3.5
@export var recovery_breath_time: float = 2.0

var sprint_timer: Timer
var recovery_breath_timer: Timer

## TODO - MANAGE SPRINT TIME TO NOT BE RESET AND RECOVER IT GRADUALLY UNTIL REACH THIS STATE AGAIN
func ready() -> void:
	super.ready()
	_create_sprint_timer()
	_create_recovery_breath_timer()


func enter():
	super.enter()
	actor.velocity.y = 0
	
	if sprint_time > 0 and is_instance_valid(sprint_timer):
		sprint_timer.start(sprint_time)

	
func physics_update(delta):
	super.physics_update(delta)
	
	if actor.motion_input.input_direction.is_zero_approx() or not OmniKitInputHelper.action_pressed_and_exists(InputControls.RunAction):
		FSM.change_state_to(WalkState)
	
	accelerate(delta)
	
	detect_slide()
	detect_jump()
	detect_dash()
	
	stair_step_up()
	actor.move_and_slide()
	stair_step_down()
	
	#actor.footsteps_manager.footstep(0.3)

	
func _create_sprint_timer() -> void:
	if not sprint_timer:
		sprint_timer = OmniKitTimeHelper.create_physics_timer(sprint_time, false, true)
		sprint_timer.name = "RunSprintTimer"
		
		add_child(sprint_timer)
		sprint_timer.timeout.connect(on_sprint_timer_timeout)


func _create_recovery_breath_timer() -> void:
	if not recovery_breath_timer:
		recovery_breath_timer = OmniKitTimeHelper.create_physics_timer(recovery_breath_time, false, true)
		recovery_breath_timer.name = "RunCatchingBreathTimer"
		add_child(recovery_breath_timer)


func on_sprint_timer_timeout() -> void:
	recovery_breath_timer.start(recovery_breath_time)
	FSM.change_state_to(WalkState)
