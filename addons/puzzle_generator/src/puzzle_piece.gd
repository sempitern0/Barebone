## This Sprite has the original PuzzleImage texture assigned so we can create a region from it with the selected mask
class_name PuzzlePiece extends Sprite2D

signal dragged
signal released

@export_flags_2d_physics var piece_layer: int 
@export_flags_2d_physics var piece_mask: int 

@onready var detection_button: Button = $DetectionButton
@onready var top_area: Area2D = $TopArea
@onready var bottom_area: Area2D = $BottomArea
@onready var right_area: Area2D = $RightArea
@onready var left_area: Area2D = $LeftArea
@onready var top_collision: CollisionShape2D = %TopCollision
@onready var bottom_collision: CollisionShape2D = %BottomCollision
@onready var right_collision: CollisionShape2D = %RightCollision
@onready var left_collision: CollisionShape2D = %LeftCollision

var row: int = 0
var col: int = 0
var piece_size: int = 0
var region: Rect2
var sides: Dictionary
var mask: Texture2D
var mask_shader_material: ShaderMaterial

var top_neighbor: PuzzlePiece
var right_neighbor: PuzzlePiece
var bottom_neighbor: PuzzlePiece
var left_neighbor: PuzzlePiece

var active_areas: Array[Area2D] = []
var opposite_neighbours: Dictionary[String, Dictionary] = {}


func _ready() -> void:
	assert(texture != null, "PuzzlePiece: The puzzle pieces needs a texture before adding it on the SceneTree")
	assert(mask_shader_material != null, "PuzzlePiece: The puzzle pieces needs a mask shader material before adding it on the SceneTree")
	
	_prepare_mask_shader_material()
	_prepare_border_areas()
	

	opposite_neighbours = {
		"top": {"opposite_side": "bottom", "neighbor": top_neighbor},
		"bottom": {"opposite_side": "top", "neighbor": bottom_neighbor},
		"left": {"opposite_side": "right", "neighbor": left_neighbor},
		"right": {"opposite_side": "left", "neighbor": right_neighbor},
	}
	
	detection_button.self_modulate.a8 = 0
	detection_button.button_down.connect(on_drag_started)
	detection_button.button_up.connect(on_drag_release)
	detection_button.anchors_preset = Control.PRESET_FULL_RECT


func root() -> PuzzlePiece:
	var parent: Node = get_parent()
	
	return parent if parent != null and parent is PuzzlePiece else self


func active_pieces() -> Array[PuzzlePiece]:
	var pieces: Array[PuzzlePiece] = [root()]
	pieces.append_array(pieces.front()\
		.get_children()\
		.filter(func(child: Node): return child is PuzzlePiece)
		)
		
	return pieces


func border_areas_detection_mode() -> void:
	for area: Area2D in active_areas.filter(func(area: Area2D): return not area.is_queued_for_deletion()):
		area.collision_layer = 1
		area.collision_mask = piece_mask
		

func border_areas_detected_mode() -> void:
	for area: Area2D in active_areas.filter(func(area: Area2D): return not area.is_queued_for_deletion()):
		area.collision_layer = piece_layer
		area.collision_mask = 0
		
		
func remove_side_area(area: Area2D) -> void:
		active_areas.erase(area)
		
		if not area.is_queued_for_deletion():
			area.queue_free()
	

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
	top_area.collision_layer = piece_layer
	top_area.collision_mask = 0
	bottom_area.collision_layer = piece_layer
	bottom_area.collision_mask = 0
	left_area.collision_layer = piece_layer
	left_area.collision_mask = 0
	right_area.collision_layer = piece_layer
	right_area.collision_mask = 0
	
	top_area.monitoring = true
	bottom_area.monitoring = true
	right_area.monitoring = true
	left_area.monitoring = true
	
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
	dragged.emit()
	

func on_drag_release() -> void:
	released.emit()
