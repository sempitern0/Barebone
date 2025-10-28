class_name ThirdPersonAirState extends MachineState

@export var actor: ThirdPersonController
@export var gravity_force: float = 9.8
@export var air_speed: float = 3.0
@export var air_side_speed: float = 2.5
@export var air_acceleration: float = 15.0
@export var air_friction: float = 10.0
@export var maximum_fall_velocity: float = 25.0


func physics_update(delta: float):
	if not actor.is_on_floor():
		apply_gravity(gravity_force, delta)


func accelerate(direction: Vector3, delta: float = get_physics_process_delta_time()) -> void:
	if air_acceleration > 0:
		actor.velocity = actor.velocity.move_toward(direction * air_speed, delta * air_acceleration)
	else:
		actor.velocity = direction * air_speed


func decelerate(delta: float = get_physics_process_delta_time()) -> void:
	if air_friction > 0:
		actor.velocity = lerp(actor.velocity, Vector3.ZERO, clampf(air_friction * delta, 0, 1.0))
	else:
		actor.velocity = Vector3.ZERO


func apply_gravity(force: float = gravity_force, delta: float = get_physics_process_delta_time()):
	actor.velocity += OmniKitVectorHelper\
		.up_direction_opposite_vector3(actor.up_direction) * force * delta


func limit_fall_velocity() -> void:
	var up_direction_opposite = OmniKitVectorHelper.up_direction_opposite_vector3(actor.up_direction)
	
	if up_direction_opposite in [Vector3.DOWN, Vector3.UP]:
		actor.velocity.y = max(sign(up_direction_opposite.y) * maximum_fall_velocity, actor.velocity.y)
	else:
		actor.velocity.x = max(sign(up_direction_opposite.x) * maximum_fall_velocity, actor.velocity.x)
