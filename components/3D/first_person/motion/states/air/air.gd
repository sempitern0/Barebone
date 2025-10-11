class_name AirState extends MachineState

@export var actor: FirstPersonController
@export_group("Parameters")
@export var gravity_force: float = 9.8
@export var air_speed: float = 3.0
@export var air_side_speed: float = 2.5
@export var air_acceleration: float = 15.0
@export var air_friction: float = 10.0
@export var maximum_fall_velocity: float = 25.0

var current_air_speed: float = 0.0
var gravity_enabled: bool = true

func physics_update(delta: float):
	apply_gravity(gravity_force, delta)
	air_move(delta)
	limit_fall_velocity()


func apply_gravity(force: float = gravity_force, delta: float = get_physics_process_delta_time()):
	if gravity_enabled:
		actor.velocity += OmniKitVectorHelper\
			.up_direction_opposite_vector3(actor.up_direction) * force * delta


func air_move(delta: float = get_physics_process_delta_time()) -> void:
	accelerate(delta)


func accelerate(delta: float = get_physics_process_delta_time()) -> void:
	var direction: Vector3 = actor.motion_input.world_coordinate_space_direction
	current_air_speed = get_speed()
	
	if air_acceleration > 0:
		actor.velocity.x = lerp(actor.velocity.x, direction.x * current_air_speed, clampf(air_acceleration * delta, 0, 1.0))
		actor.velocity.z = lerp(actor.velocity.z, direction.z * current_air_speed, clampf(air_acceleration * delta, 0, 1.0))
	else:
		actor.velocity = Vector3(
			actor.velocity.x * direction.x * current_air_speed, 
			actor.velocity.y, 
			actor.velocity.x * direction.z * current_air_speed 
		)


func get_speed() -> float:
	if actor.motion_input.input_direction in OmniKitVectorHelper.horizontal_directions_v2:
		return air_side_speed
		
	return air_speed


func limit_fall_velocity() -> void:
	var up_direction_opposite = OmniKitVectorHelper.up_direction_opposite_vector3(actor.up_direction)
	
	if up_direction_opposite in [Vector3.DOWN, Vector3.UP]:
		actor.velocity.y = max(sign(up_direction_opposite.y) * maximum_fall_velocity, actor.velocity.y)
	else:
		actor.velocity.x = max(sign(up_direction_opposite.x) * maximum_fall_velocity, actor.velocity.x)


func detect_jump() -> void:
	if actor.jump and OmniKitInputHelper.action_just_pressed_and_exists(InputControls.JumpAction):
		FSM.change_state_to(JumpState)


func detect_wall_jump() -> void:
	if actor.can_wall_jump() and OmniKitInputHelper.action_just_pressed_and_exists(InputControls.JumpAction):
		FSM.change_state_to(WallJumpState)


func detect_dash() -> void:
	if actor.dash and \
		 not actor.motion_input.world_coordinate_space_direction.is_zero_approx() and \
		 OmniKitInputHelper.action_just_pressed_and_exists(InputControls.DashAction):
		
		FSM.change_state_to(DashState)
