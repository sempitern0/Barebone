class_name WeaponMotion extends Node3D

@export var actor: FirstPersonController

func enable() -> void:
	set_physics_process(true)
	
	
func disable() -> void:
	set_physics_process(false)


func is_enabled() -> bool:
	return is_physics_processing()


func is_disabled() -> bool:
	return not is_physics_processing()
