class_name Arrow extends RigidBody3D

@export var collision_shape: CollisionShape3D
@export var hit_raycast: RayCast3D
@export var time_alive: float = 5.0

var alive_timer: Timer
var collided: bool = false


func _ready() -> void:
	collision_layer = Globals.arrows_collision_layer
	collision_mask = Globals.world_collision_layer | Globals.enemies_collision_layer | Globals.grabbables_collision_layer
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	
	_create_alive_timer()


func _physics_process(delta: float) -> void:
	## I suck at trigonometry so I apply a minimal rotation.x to achieve a parabolic movement
	## and that the arrow doesn't shoot and fall on its ass
	rotation.x -= 0.5 * delta
	rotation.x = maxf(rotation.x, deg_to_rad(-75.0))
	
	if hit_raycast.is_colliding():
		reparent(hit_raycast.get_collider())
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		freeze = true
		collision_shape.disabled = true
		hit_raycast.enabled = false
		collided = true
		set_physics_process(false)


func _create_alive_timer() -> void:
	alive_timer = OmniKitTimeHelper.create_physics_timer(time_alive, true, true)
	add_child(alive_timer)
	alive_timer.timeout.connect(on_alive_timer_timeout)
	
	
func on_alive_timer_timeout() -> void:
	if not collided:
		queue_free()

#func _integrate_forces(state: PhysicsDirectBodyState3D):
	#if hit_raycast.enabled and not hit_raycast.is_colliding():
		#look_at(global_transform.origin + linear_velocity, Vector3.UP)
