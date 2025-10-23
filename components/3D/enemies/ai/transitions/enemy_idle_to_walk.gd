class_name EnemyIdleToWalkTransition extends MachineTransition


func should_transition() -> bool:
	return parameters.has("next_position") \
		and from_state is EnemyIdleState \
		and to_state is EnemyWalkState

	
func on_transition():
	if to_state is EnemyWalkState:
		to_state.next_position = parameters.next_position
	
