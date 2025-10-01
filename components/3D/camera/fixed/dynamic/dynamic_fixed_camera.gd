## Type of Camera being used by third person survival horrors with fixed camera like Silent Hill, RE2, Tormented souls...
class_name DynamicFixedCamera3D extends Camera3D

@export var target: Node3D:
	set(value):
		target = value
		enable_follow()
@export var follow: bool  = true:
	set(value):
		follow = value
		enable_follow()
@export var follow_distance: float  = 5.0
@export var follow_speed: float  = 2.0
@export var turn_speed: float  = 80.0
@export var move_position: bool = false
@export var use_rotation_y: bool = true
@export var use_rotation_x: bool = false
@export var reset_transform_when_leave: bool = true

var original_transform: Transform3D

func _ready() -> void:
	original_transform = global_transform
	enable_follow()


func _physics_process(delta: float) -> void:
	var direction_to_target: Vector3 = target.global_transform.origin - global_transform.origin
	var distance_to_target: float = direction_to_target.length()
	
	var move_vector = direction_to_target
	move_vector.y = 0
	
	direction_to_target = direction_to_target.normalized()
	
	if move_position:
		var acceleration = distance_to_target - follow_distance
		global_transform.origin += acceleration * move_vector * follow_speed * delta
	
	if use_rotation_y:
		rotation_degrees.y += turn_speed * -direction_to_target.dot(global_transform.basis.x) * delta
	
	if use_rotation_x:
		rotation_degrees.x += turn_speed * direction_to_target.dot(global_transform.basis.y) * delta


func activate() -> void:
	make_current()
	call_deferred("enable_follow")


func deactivate() -> void:
	clear_current()
	
	if reset_transform_when_leave:
		set_deferred("global_transform", original_transform)
	
	set_physics_process(false)


func enable_follow() -> void:
	set_physics_process(current and target != null and follow)
