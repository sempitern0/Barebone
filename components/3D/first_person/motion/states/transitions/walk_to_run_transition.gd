class_name WalkToRunTransition extends MachineTransition


func should_transition() -> bool:
	if from_state is WalkState and to_state is RunState:
		return from_state.actor.run and to_state.recovery_breath_timer.is_stopped()
	
	return false
	
