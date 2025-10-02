class_name ThirdPersonClickController extends ThirdPersonController

@export var max_click_position_distance: float = 10.0
@export var can_change_click_position_while_moving: bool = true
@export var navigation_agent: NavigationAgent3D


func _ready() -> void:
	motion_state_machine.register_transition(
		ThirdPersonClickModeNeutralState, 
		ThirdPersonClickModeMovementState,
		ThirdPersonNeutralToMovementTransition.new()
	)


func look_at_mouse() -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var world_direction: Vector3 = camera.project_ray_normal(mouse)

	if world_direction.y != 0:
		var distance: float= -origin.y / world_direction.y
		var look_position: Vector3 = origin + world_direction * distance
		
		look_at(Vector3(look_position.x, global_position.y, look_position.z))

	
func can_move_to_next_click_position(next_position: Vector3) -> bool:
	return global_position.distance_to(next_position) <= max_click_position_distance
