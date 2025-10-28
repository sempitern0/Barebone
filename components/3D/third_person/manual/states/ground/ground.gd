class_name ThirdPersonGroundState extends MachineState

@export var actor: ThirdPersonController
@export var gravity_force: float = 9.8
@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 20.0


func physics_update(delta: float):
	if not actor.is_on_floor():
		apply_gravity(gravity_force, delta)

	if gravity_force > 0 and actor.is_falling():
		FSM.change_state_to(ThirdPersonFallState)


func accelerate(direction: Vector3, delta: float = get_physics_process_delta_time()) -> void:
	if acceleration > 0:
		actor.velocity = actor.velocity.move_toward(direction * speed, delta * acceleration)
	else:
		actor.velocity = direction * speed


func decelerate(delta: float = get_physics_process_delta_time()) -> void:
	if friction > 0:
		actor.velocity = lerp(actor.velocity, Vector3.ZERO, clampf(friction * delta, 0, 1.0))
	else:
		actor.velocity = Vector3.ZERO


func apply_gravity(force: float = gravity_force, delta: float = get_physics_process_delta_time()):
	actor.velocity += OmniKitVectorHelper\
		.up_direction_opposite_vector3(actor.up_direction) * force * delta
