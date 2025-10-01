class_name BulletTrace extends Node3D

@export var speed: float = 50.0
@export var alive_time: float = 1.0

var alive_timer: Timer 


var shoot_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	if alive_timer == null:
		alive_timer = OmniKitTimeHelper.create_physics_timer(alive_time, true, true)
		alive_timer.name = "AliveTimer"
		add_child(alive_timer)
		alive_timer.timeout.connect(on_alive_timer_timeout)
		
	top_level = true
	
	if shoot_direction.is_zero_approx():
		shoot_direction = OmniKitCamera3DHelper.forward_direction(get_viewport().get_camera_3d())
	
	
func _physics_process(delta: float) -> void:
	global_position += shoot_direction * speed * delta


func on_alive_timer_timeout() -> void:
	queue_free()
