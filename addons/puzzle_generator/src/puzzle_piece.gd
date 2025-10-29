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

var region: Rect2
var sides: Dictionary
var mask: Texture2D
var mask_shader_material: ShaderMaterial

var top_neighbor: PuzzlePiece
var right_neighbor: PuzzlePiece
var bottom_neighbor: PuzzlePiece
var left_neighbor: PuzzlePiece


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

	left_collision.shape.set_size(Vector2(region_rect.size.x / 4, region_rect.size.y))
	left_collision.position = Vector2(-region_rect.size.x / 4 + -region_rect.size.x / 8, 0)
	
	right_collision.shape.set_size(Vector2(region_rect.size.x / 4, region_rect.size.y))
	right_collision.position = Vector2(region_rect.size.x / 4 + region_rect.size.x / 8, 0)
	
	top_collision.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y / 4))
	top_collision.position = Vector2(0, -region_rect.size.y / 4 + -region_rect.size.y / 8)
	
	bottom_collision.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y / 4))
	bottom_collision.position = Vector2(0, region_rect.size.y / 4 + region_rect.size.y / 8)


func on_drag_started() -> void:
	top_area.monitoring = true
	bottom_area.monitoring = true
	right_area.monitoring = true
	left_area.monitoring = true
	
	top_area.monitorable = false
	bottom_area.monitorable = false
	right_area.monitorable = false
	left_area.monitorable = false


func on_drag_release() -> void:	
	top_area.monitoring = false
	bottom_area.monitoring = false
	right_area.monitoring = false
	left_area.monitoring = false
	
	top_area.monitorable = true
	bottom_area.monitorable = true
	right_area.monitorable = true
	left_area.monitorable = true
