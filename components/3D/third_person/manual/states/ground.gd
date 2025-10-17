class_name ThirdPersonGroundState extends MachineState

@export var actor: CharacterBody3D
@export var gravity_force: float = 9.8
@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 20.0


func physics_update(delta: float):
	if not actor.is_on_floor():
		apply_gravity(gravity_force, delta)


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


func rotate_skin(target_direction: Vector3, delta: float = get_physics_process_delta_time()) -> void:
	if actor.skin:
		var target_angle: float = Vector3.FORWARD.signed_angle_to(target_direction, Vector3.UP)
		
		if actor.skin_rotation_speed > 0:
			actor.skin.global_rotation.y = lerp_angle(
				actor.skin.global_rotation.y, 
				target_angle, 
				delta * actor.skin_rotation_speed)
		else:
			actor.skin.global_rotation.y = target_angle
