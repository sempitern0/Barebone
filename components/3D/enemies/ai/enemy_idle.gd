class_name EnemyIdleState extends EnemyGroundState

@export_group("Patrol")
@export var patrol: bool = true
@export var patrol_radius: float = 20.0
@export var patrol_interval_min: float = 2.5
@export var patrol_interval_max: float = 5.0

var patrol_timer: Timer


func ready() -> void:
	_prepare_patrol_timer()


func enter() -> void:
	actor.play_idle_animation()
	
	if patrol:
		patrol_timer.start(randf_range(patrol_interval_min, patrol_interval_max))


func exit(_next_state: MachineState) -> void:
	patrol_timer.stop()


func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if actor.is_on_floor():
		decelerate(delta)
	
	actor.move_and_slide()


func _prepare_patrol_timer() -> void:
	if patrol_timer == null:
		patrol_timer = OmniKitTimeHelper.create_idle_timer(randf_range(patrol_interval_min, patrol_interval_max))
		add_child(patrol_timer)
		patrol_timer.timeout.connect(on_patrol_timer_timeout)
		
		
func on_patrol_timer_timeout() -> void:
	if actor.velocity.is_zero_approx():
		FSM.change_state_to(
		EnemyWalkState, 
		{"next_position": actor.get_random_navigation_point_in_radius(actor.global_position, patrol_radius)}
		)
