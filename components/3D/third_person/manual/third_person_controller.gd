class_name ThirdPersonController extends CharacterBody3D

@export var skin: Node3D
@export var skin_rotation_speed: float = 5.0

@onready var camera: Camera3D = %Camera3D
@onready var motion_state_machine: Machina = $MotionStateMachine

var motion_input: OmniKitMotionInput = OmniKitMotionInput.new(self)


func _process(_delta: float) -> void:
	motion_input.update()
