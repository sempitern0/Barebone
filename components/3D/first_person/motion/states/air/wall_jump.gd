class_name WallJumpState extends AirState

@export var wall_jump_force: float = 7.0
@export_range(0.0, 1.0, 0.01) var wall_jump_up_factor: float = 0.5

var current_wall_normal: Vector3 = Vector3.ZERO


func enter() -> void:
	current_wall_normal = actor.last_wall_normal
	
	var jump_direction: Vector3 = current_wall_normal.slerp(actor.up_direction, wall_jump_up_factor).normalized()
	actor.velocity += jump_direction * wall_jump_force
	
	actor.move_and_slide()


func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	if (not actor.was_grounded and actor.is_grounded):
		if actor.motion_input.input_direction.is_zero_approx():
			FSM.change_state_to(IdleState)
		else:
			FSM.change_state_to(WalkState)
			
	elif actor.is_falling():
		FSM.change_state_to(FallState)
	
	actor.move_and_slide()
