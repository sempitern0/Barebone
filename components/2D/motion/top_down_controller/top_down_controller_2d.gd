class_name TopDownController2D extends CharacterBody2D

@export var base_speed: float = 50

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow_sprite: Sprite2D = $AnimatedSprite2D/ShadowSprite
@onready var camera: Camera2D = $Camera2D

var motion_input: OmniKitMotionInput = OmniKitMotionInput.new()
var last_direction: Vector2 = Vector2.DOWN


func _physics_process(_delta: float) -> void:
	motion_input.update()
	_manage_animations(motion_input.input_direction)
			
	velocity = motion_input.input_direction * base_speed
	move_and_slide()

	
func _ready() -> void:
	animated_sprite.play("idle_down")


func _manage_animations(input_direction: Vector2, include_diagonals: bool = true) -> void:
	match motion_input.input_direction:
		Vector2.UP:
			animated_sprite.play("walk_up")
		Vector2.DOWN:
			animated_sprite.play("walk_down")
		Vector2.RIGHT:
			animated_sprite.play("walk_right")
		Vector2.LEFT:
			animated_sprite.play("walk_left")
		Vector2.ZERO:
			match motion_input.previous_input_direction:
				Vector2.DOWN:
					animated_sprite.play("idle_down") 
				Vector2.UP:
					animated_sprite.play("idle_up") 
				Vector2.RIGHT:
					animated_sprite.play("idle_right")
				Vector2.LEFT:
					animated_sprite.play("idle_left")
	
	if include_diagonals and OmniKitVectorHelper.is_diagonal_direction_v2(input_direction):
		match sign(motion_input.input_direction.y):
				1.0:
					animated_sprite.play("walk_down")
				-1.0:
					animated_sprite.play("walk_up")
