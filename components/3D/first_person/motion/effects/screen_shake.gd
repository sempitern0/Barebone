class_name ScreenShake extends Node3D

const MinScreenShake: float = 0.05
const MaxScreenShake: float = 0.5

@export var pivot_node: Node3D:
	set(new_pivot):
		pivot_node = new_pivot
		
		if pivot_node:
			original_pivot_position = pivot_node.position
			horizontal_offset = original_pivot_position.z
			vertical_offset = original_pivot_position.y
			
@export var shake_smoothness: float = 15.0

var screen_shake_tween: Tween
var horizontal_offset: float = 0.0
var vertical_offset: float = 0.0
var original_pivot_position: Vector3


func _ready() -> void:
	original_pivot_position = pivot_node.position
	horizontal_offset = original_pivot_position.z
	vertical_offset = original_pivot_position.y
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	pivot_node.position.y = lerpf(pivot_node.position.y, vertical_offset, delta * shake_smoothness)
	pivot_node.position.z = lerpf(pivot_node.position.z, horizontal_offset, delta * shake_smoothness)
	

func add(amount: float, duration: float) -> void:
	set_physics_process(true)
	
	if screen_shake_tween:
		screen_shake_tween.kill()
		
	screen_shake_tween = create_tween()
	screen_shake_tween.tween_method(update_screen_shake.bind(amount), 0.0, 1.0, duration)\
		.set_ease(Tween.EASE_OUT)
	await screen_shake_tween.finished
	
	set_physics_process(false)
	
	
func update_screen_shake(alpha: float, amount: float) -> void:
	amount = remap(amount, 0.0, 1.0, MinScreenShake, MaxScreenShake)
	
	var current_shake_amount = amount * (1.0 - alpha)
	horizontal_offset = original_pivot_position.z + randf_range(-current_shake_amount, current_shake_amount)
	vertical_offset = original_pivot_position.y +  randf_range(-current_shake_amount, current_shake_amount)
