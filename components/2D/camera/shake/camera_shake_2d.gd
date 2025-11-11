@icon("res://components/2D/camera/shake/camera_shake_2d.svg")
class_name CameraShake2D extends Node2D

signal shake_started
signal shake_finished

@export var camera: Camera2D
@export var default_duration: float = 0.5
@export var default_strength: float = 25.0

var _shake_tween: Tween
		
func shake(duration: float = default_duration, strength: float = default_strength) -> void:
	if not is_instance_valid(camera):
		push_error("CameraShake2D: This node %s does not have a valid Camera2D assigned, aborting shake..." % name)
		return
		
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	
	var camera_base_offset: Vector2 = camera.offset
	
	shake_started.emit()
	_shake_tween = create_tween()
	_shake_tween.tween_method(_run_shake.bind(camera_base_offset, strength), 1.0, 0.0, duration)
	_shake_tween.finished.connect(func(): shake_finished.emit(), CONNECT_ONE_SHOT)


func _run_shake(delay: float, base_offset: Vector2,  strength: float) -> void:
	var movement:Vector2 = OmniKitVectorHelper.generate_2d_random_direction() * strength * delay
	camera.offset = base_offset + movement 
