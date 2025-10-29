class_name ThirdPersonWeapon extends Node3D

@export var skin: Node3D
@export var bone_position: Vector3
@export var bone_rotation: Vector3
@export var bone_scale: Vector3

## We assume the weapon is added as child of BoneAttachment3D so we can adjust
## the entire transform to fit the animations.
func _ready() -> void:
	position = bone_position
	rotation = bone_rotation
	scale = bone_scale
	
	skin.position = Vector3.ZERO
