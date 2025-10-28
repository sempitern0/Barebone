class_name ThirdPersonRunState extends ThirdPersonGroundState

var last_move_direction: Vector3 = Vector3.BACK


func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not actor.detect_run():
		FSM.change_state_to(ThirdPersonWalkState)
		return
		
	var move_direction = actor.move_direction_based_on_camera(actor.camera, actor.motion_input.input_direction)

	accelerate(move_direction, delta)
		
	if move_direction.length() > 0.2:
		last_move_direction = move_direction
	
	
	actor.rotate_skin(last_move_direction)
	actor.move_and_slide()
