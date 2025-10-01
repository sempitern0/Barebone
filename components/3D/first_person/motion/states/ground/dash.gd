class_name DashState extends GroundState

@export var speed_multiplier: float = 2.0
@export var dash_time: float = 0.35
@export var dash_recovery_time: float = 0.5
@export var dash_times: int = 1
@export var jump_amount: float = 0.0

var dash_timer: Timer
var current_dash: int = 0
var base_speed: float = 0.0
var last_state: MachineState


func ready() -> void:
	if dash_timer == null:
		dash_timer = OmniKitTimeHelper.create_physics_timer(dash_time, false, true)
		dash_timer.name = "DashTimer"
		add_child(dash_timer)
		dash_timer.timeout.connect(on_dash_timer_timeout)


func enter() -> void:
	super.enter()
	
	last_state = FSM.last_state()
	base_speed = _calculate_base_speed(last_state)
	
	dash()
	
	
func exit(next: MachineState) -> void:
	super.exit(next)
	current_dash = 0
	base_speed = 0.0
	
	if dash_timer.time_left > 0:
		dash_timer.stop()
	
	
func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if last_state is GroundState:
		#detect_slide()
		detect_jump()
	
	if current_dash < dash_times:
		detect_dash()
	
	stair_step_up()
	actor.move_and_slide()
	stair_step_down()


func dash() -> void:
	if is_instance_valid(dash_timer):
		dash_timer.start(dash_time)
		
	if last_state is GroundState:
		base_speed = last_state.speed
	elif last_state is AirState:
		base_speed = last_state.air_speed
	
	actor.velocity = (base_speed * speed_multiplier) * actor.motion_input.world_coordinate_space_direction
	actor.velocity += actor.up_direction * jump_amount
	actor.move_and_slide()
	
	current_dash += 1
	

func _calculate_base_speed(from_state: MachineState) -> float:
	var result: float = 0.0
	
	if from_state is GroundState:
		result = from_state.speed
	elif from_state is AirState:
		result = from_state.air_speed
	
	return result


func on_dash_timer_timeout() -> void:
	if last_state is GroundState:
		FSM.change_state_to(WalkState)
	elif last_state is AirState:
		FSM.change_state_to(FallState)
