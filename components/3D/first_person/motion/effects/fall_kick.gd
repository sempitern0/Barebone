@icon("res://components/3D/first_person/motion/effects/head.svg")
class_name FallKick extends Node3D

@export var actor: FirstPersonController
@export var pivot_node: Node3D
@export var enabled: bool = true
## The duration of the fall kick
@export var fall_time: float = 0.1
## The velocity y threshold that start increasing the fall kick strength
@export var fall_speed_threshold: float = 1
## The angle increment step when the fall speed increases by 1
@export_range(0, 360.0, 0.01, "degrees") var fall_step_angle: float = 0.5
@export_range(0, 360.0, 0.01, "degrees") var max_fall_strength_angle: float = 3.5


func add(fall_strength: float, time: float = fall_time) -> void:
	if enabled and fall_strength > 0:
		var original_position_y: float = pivot_node.position.y
		var fall_value = fall_strength
		
		if absf(actor.velocity.y) >= fall_speed_threshold:
			fall_strength += minf(max_fall_strength_angle, (absf(actor.velocity.y) * fall_step_angle))
		
		fall_value = [1, -1].pick_random() * deg_to_rad(fall_value)
		
		var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(pivot_node, "rotation:z", pivot_node.rotation.z + fall_value, time)
		tween.tween_property(pivot_node, "position:y", pivot_node.position.y + fall_value * 2, time)
		tween.chain()
		tween.tween_property(pivot_node, "rotation:z", 0.0, fall_time)
		tween.tween_property(pivot_node, "position:y", original_position_y, time)
