class_name PuzzleBackground extends Sprite2D

@export_range(0.0, 255.0, 0.1) var transparency: float = 75.0:
	set(value):
		transparency = value
		self_modulate.a8 = transparency


func _enter_tree() -> void:
	name = "TransparentBackgroundPuzzle"


func _ready() -> void:
	self_modulate.a8 = transparency
	centered = true

## This is the final size scaled to position the puzzle mosaic that displays the puzzle as background
func half_size() -> Vector2:
	if texture == null:
		return Vector2.ZERO
		
	return (texture.get_size() * scale) / 2.0
