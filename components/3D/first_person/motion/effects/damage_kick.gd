@icon("res://components/3D/first_person/motion/effects/head.svg")
class_name DirectionalDamageKick extends Node3D

@export var actor: FirstPersonController
@export var pivot_node: Node3D
@export var enabled: bool = true
@export var kick_time: float = 0.05


func add(pitch: float, roll: float, source: Vector3, time: float = kick_time) -> void:
	if enabled and pitch > 0 and roll > 0 and time > 0:
		var forward: Vector3 = global_transform.basis.z
		var right: Vector3 = global_transform.basis.x
		var direction: Vector3 = global_position.direction_to(source)
		var forward_dot: float = direction.dot(forward)
		var right_dot: float = direction.dot(right)
		
		var damage_pitch: float = deg_to_rad(pitch) * forward_dot
		var damage_roll: float = deg_to_rad(roll) * right_dot
		
		var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(pivot_node, "rotation:x", pivot_node.rotation.x + damage_pitch, time)
		tween.tween_property(pivot_node, "rotation:z", pivot_node.rotation.z + damage_roll, time)
		tween.chain()
		tween.tween_property(pivot_node, "rotation:z", 0.0, time)
		tween.tween_property(pivot_node, "rotation:x", pivot_node.rotation.x - damage_pitch, time)
