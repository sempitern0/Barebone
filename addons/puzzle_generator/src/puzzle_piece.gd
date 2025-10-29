## This Sprite has the original PuzzleImage texture assigned so we can create a region from it with the selected mask
class_name PuzzlePiece extends Sprite2D

var region: Rect2
var sides: Dictionary
var mask: Texture2D
var mask_shader_material: ShaderMaterial

var top_neighbor: PuzzlePiece
var right_neighbor: PuzzlePiece
var bottom_neighbor: PuzzlePiece
var left_neighbor: PuzzlePiece


func _ready() -> void:
	_prepare_mask_shader_material()


func _prepare_mask_shader_material() -> void:
	var texture_size: Vector2 = texture.get_size()
	var uv_pos: Vector2 = region_rect.position / texture_size
	var uv_size: Vector2 = region_rect.size / texture_size
	var region_uv_data: Vector4 = Vector4(uv_pos.x, uv_pos.y, uv_size.x, uv_size.y)
	
	material = mask_shader_material.duplicate()
	material.set("shader_parameter/mask_texture", mask)
	material.set("shader_parameter/mask_resolution", mask.get_size())
	material.set("shader_parameter/region_rect_uv_data", region_uv_data)
