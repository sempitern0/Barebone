## This Sprite has the original PuzzleImage texture assigned so we can create a region from it with the selected mask
class_name PuzzlePiece extends Sprite2D

@onready var top_area: Area2D = $TopArea
@onready var bottom_area: Area2D = $BottomArea
@onready var right_area: Area2D = $RightArea
@onready var left_area: Area2D = $LeftArea
@onready var top_collision: CollisionShape2D = %TopCollision
@onready var bottom_collision: CollisionShape2D = %BottomCollision
@onready var right_collision: CollisionShape2D = %RightCollision
@onready var left_collision: CollisionShape2D = %LeftCollision
@onready var draggable: OmniKitDraggable2D = $OmniKitDraggable2D

var row: int = 0
var col: int = 0
var region: Rect2
var sides: Dictionary
var mask: Texture2D
var mask_shader_material: ShaderMaterial

var top_neighbor: PuzzlePiece
var right_neighbor: PuzzlePiece
var bottom_neighbor: PuzzlePiece
var left_neighbor: PuzzlePiece

var active_areas: Array[Area2D] = []


func _ready() -> void:
	assert(texture != null, "PuzzlePiece: The puzzle pieces needs a texture before adding it on the SceneTree")
	assert(mask_shader_material != null, "PuzzlePiece: The puzzle pieces needs a mask shader material before adding it on the SceneTree")
	
	_prepare_mask_shader_material()
	_prepare_border_areas()
	
	draggable.dragged.connect(on_drag_started)
	draggable.released.connect(on_drag_release)
	
	
func _prepare_mask_shader_material() -> void:
	var texture_size: Vector2 = texture.get_size()
	var uv_pos: Vector2 = region_rect.position / texture_size
	var uv_size: Vector2 = region_rect.size / texture_size
	var region_uv_data: Vector4 = Vector4(uv_pos.x, uv_pos.y, uv_size.x, uv_size.y)
	
	material = mask_shader_material.duplicate()
	material.set("shader_parameter/mask_texture", mask)
	material.set("shader_parameter/mask_resolution", mask.get_size())
	material.set("shader_parameter/region_rect_uv_data", region_uv_data)


func _prepare_border_areas() -> void:
	top_area.monitoring = false
	bottom_area.monitoring = false
	right_area.monitoring = false
	left_area.monitoring = false
	
	top_area.monitorable = true
	bottom_area.monitorable = true
	right_area.monitorable = true
	left_area.monitorable = true
	
	top_area.set_meta(&"side", "top")
	bottom_area.set_meta(&"side", "bottom")
	left_area.set_meta(&"side", "left")
	right_area.set_meta(&"side", "right")
	
	if top_neighbor == null:
		top_area.queue_free()
	else:
		top_area.position = Vector2(0, -region_rect.size.y / 4 + -region_rect.size.y / 8)
		top_collision.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y / 4))
		active_areas.append(top_area)
		
	if bottom_neighbor == null:
		bottom_area.queue_free()
	else:
		bottom_area.position = Vector2(0, region_rect.size.y / 4 + region_rect.size.y / 8)
		bottom_collision.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y / 4))
		active_areas.append(bottom_area)

	if left_neighbor == null:
		left_area.queue_free()
	else:
		left_area.position = Vector2(-region_rect.size.x / 4 + -region_rect.size.x / 8, 0)	
		left_collision.shape.set_size(Vector2(region_rect.size.x / 4, region_rect.size.y))
		active_areas.append(left_area)
		
	if right_neighbor == null:
		right_area.queue_free()
	else:
		right_area.position = Vector2(region_rect.size.x / 4 + region_rect.size.x / 8, 0)
		right_collision.shape.set_size(Vector2(region_rect.size.x / 4, region_rect.size.y))
		active_areas.append(right_area)


func on_drag_started() -> void:
	for area: Area2D in active_areas:
		area.monitoring = true
		area.monitorable = false


func on_drag_release() -> void:
	for current_side_area: Area2D in active_areas:
		var side: String = current_side_area.get_meta(&"side")
		
		match side:
			"top":
				var detected_piece_areas = current_side_area.get_overlapping_areas()\
					.filter(func(area: Area2D): return area.get_meta(&"side") == "bottom")
				
				for piece_area: Area2D in detected_piece_areas:
					var detected_piece: PuzzlePiece = piece_area.get_parent() as PuzzlePiece
					
					if top_neighbor == detected_piece:
						active_areas.erase(current_side_area)
						current_side_area.queue_free()
			"bottom":
				var detected_piece_areas = current_side_area.get_overlapping_areas()\
					.filter(func(area: Area2D): return area.get_meta(&"side") == "top")
			
				for piece_area: Area2D in detected_piece_areas:
					var detected_piece: PuzzlePiece = piece_area.get_parent() as PuzzlePiece
					
					if bottom_neighbor == detected_piece:
						active_areas.erase(current_side_area)
						current_side_area.queue_free()
			"left":
				var detected_piece_areas = current_side_area.get_overlapping_areas()\
					.filter(func(area: Area2D): return area.get_meta(&"side") == "right")
			
				for piece_area: Area2D in detected_piece_areas:
					var detected_piece: PuzzlePiece = piece_area.get_parent() as PuzzlePiece
					
					if left_neighbor == detected_piece:
						active_areas.erase(current_side_area)
						current_side_area.queue_free()
						
			"right":
				var detected_piece_areas = current_side_area.get_overlapping_areas()\
					.filter(func(area: Area2D): return area.get_meta(&"side") == "left")
			
				for piece_area: Area2D in detected_piece_areas:
					var detected_piece: PuzzlePiece = piece_area.get_parent() as PuzzlePiece
					
					if right_neighbor == detected_piece:
						active_areas.erase(current_side_area)
						current_side_area.queue_free()
		
		current_side_area.set_deferred("monitoring", false)
		current_side_area.set_deferred("monitorable", true)
