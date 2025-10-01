@icon("res://components/3D/first_person/motion/effects/head.svg")
class_name HeadBob extends Node3D

@export var actor: FirstPersonController
@export var pivot_node: Node3D
@export var enabled: bool = true:
	set(value):
		enabled = value
		set_physics_process(enabled)
		
@export_range(0, 10.0, 0.01) var bob_frequency: float = 2.0
@export_range(0, 0.4, 0.01) var bob_amplitude: float = 0.05
## Apply an absolute into the sin function to achieve a more bouncy steps.
@export var bounce_effect: bool = false

var original_head_bob_position: Vector3 = Vector3.ZERO
var bob_accumulator: float = 0.0


func _ready() -> void:
	original_head_bob_position = pivot_node.position
	
	set_physics_process(enabled)


func _physics_process(delta: float) -> void:
	var speed: float = actor.get_ground_speed()
	
	if actor.is_grounded and snappedf(speed, 0.01) > 0.2 and not actor.motion_state_machine.locked:
		bob_accumulator += delta * speed
		
		var base_position: Vector3 = original_head_bob_position
		base_position.x += cos(bob_accumulator * bob_frequency / 2.0) * bob_amplitude
		base_position.y += sin(bob_accumulator * bob_frequency) * bob_amplitude
		
		if bounce_effect:
			base_position.y += absf(base_position.y)
				
		pivot_node.position = Vector3(base_position.x, base_position.y, pivot_node.position.z)
	else:
		bob_accumulator = lerpf(bob_accumulator, 0.0, delta * 5)
		pivot_node.position.x = lerpf(pivot_node.position.x, original_head_bob_position.x, delta * 15)
		pivot_node.position.y = lerpf(pivot_node.position.y, original_head_bob_position.y, delta * 15)
	

func enable() -> void:
	enabled = true
	

func disable() -> void:
	enabled = false
