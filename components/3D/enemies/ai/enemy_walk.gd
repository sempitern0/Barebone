class_name EnemyWalkState extends EnemyGroundState

var direction: Vector3
var next_position: Vector3


func enter() -> void:
	actor.play_walk_animation()
	
	if rotation_speed == 0 or not smooth_rotation:
		actor.look_at(
			Vector3(next_position.x, actor.global_position.y, next_position.z),
			Vector3.UP
		)


func physics_update(delta: float) -> void:
	super.physics_update(delta)
	actor.global_transform = actor.global_transform.interpolate_with(actor.align_transform_with_floor(), 0.3)
	
	actor.navigation_agent.target_position = next_position
	direction = actor.global_position.direction_to(actor.navigation_agent.get_next_path_position())
	
	if smooth_rotation and rotation_speed > 0:
		actor.rotation.y = lerp_angle(actor.rotation.y, atan2(-direction.x, -direction.z), delta * rotation_speed)
	
	actor.velocity = direction * speed
	actor.move_and_slide()
	
	if actor.navigation_agent.is_navigation_finished():
		FSM.change_state_to(EnemyIdleState)
