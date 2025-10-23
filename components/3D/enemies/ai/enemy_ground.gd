class_name EnemyGroundState extends MachineState

@export var actor: Enemy
@export_group("Parameters")
@export var gravity_force: float = 9.8
@export var speed: float = 3.0
@export var side_speed: float = 2.5
@export var acceleration: float = 8.0
@export var friction: float = 10.0
@export var smooth_rotation: bool = false
@export var rotation_speed: float = 5.0


func physics_update(delta: float):
	if not actor.is_on_floor():
		apply_gravity(gravity_force, delta)
		
	#if gravity_force > 0 and actor.is_falling():
		#FSM.change_state_to(FallState)


func apply_gravity(force: float = gravity_force, delta: float = get_physics_process_delta_time()):
	actor.velocity += OmniKitVectorHelper\
		.up_direction_opposite_vector3(actor.up_direction) * force * delta


func decelerate(delta: float = get_physics_process_delta_time()) -> void:
	if friction > 0:
		actor.velocity = lerp(actor.velocity, Vector3.ZERO, clampf(friction * delta, 0, 1.0))
	else:
		actor.velocity = Vector3.ZERO
