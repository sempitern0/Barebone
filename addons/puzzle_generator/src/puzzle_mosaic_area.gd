class_name PuzzleMosaicArea extends Area2D

@export_flags_2d_physics var mosaic_layer: int

@onready var mosaic_collison: CollisionShape2D = $MosaicCollisionShape

# The puzzle piece that fits here
var puzzle_piece: PuzzlePiece:
	set(new_piece):
		puzzle_piece = new_piece
		
		if puzzle_piece and is_inside_tree():
			create_mosaic_shape(puzzle_piece.piece_size)


func _ready() -> void:
	collision_layer = mosaic_layer
	collision_mask = 0
	monitorable = true
	monitoring = false


func create_mosaic_shape(piece_size: Vector2i) -> void:
	mosaic_collison.shape.size = piece_size
