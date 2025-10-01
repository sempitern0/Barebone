@tool
@icon("res://components/3D/interactions/interactables/icons/outliner.svg")
class_name Outliner3D extends Node

const PixelPerfectShader: Shader = preload("uid://ct70pjxidp8h")

@export var interactable: Interactable3D
@export var grabbable: Grabbable3D
@export var target_meshes: Array[MeshInstance3D] = []
@export var outline_mode: OutlineMode = OutlineMode.EdgeShader:
	set(new_mode):
		if new_mode != outline_mode:
			outline_mode = new_mode
			notify_property_list_changed()
			
## https://www.videopoetics.com/tutorials/pixel-perfect-outline-shaders-unity/
@export_category("Edge shader") 
@export var outline_color: Color = Color.WHITE
@export var outline_width: float = 2.0
@export_category("Inverted hull")
@export var outline_hull_color: Color = Color.WHITE
@export_range(0, 16, 0.01) var outline_grow_amount: float = 0.02

enum OutlineMode {
	EdgeShader,
	InvertedHull
}

var outline_hull_material: StandardMaterial3D
var outline_edge_shader_material: ShaderMaterial


func _validate_property(property: Dictionary):
	if property.name in ["outline_color", "outline_width"]:
		property.usage |= PROPERTY_USAGE_READ_ONLY if outline_mode == OutlineMode.InvertedHull else PROPERTY_USAGE_DEFAULT

	if property.name in ["outline_hull_color", "outline_grow_amount"]:
		property.usage |= PROPERTY_USAGE_READ_ONLY if outline_mode == OutlineMode.EdgeShader else PROPERTY_USAGE_DEFAULT


func _ready() -> void:
	if not Engine.is_editor_hint():
		if interactable:
			interactable.focused.connect(on_interactable_focused)
			interactable.unfocused.connect(on_interactable_unfocused)
			interactable.interacted.connect(on_interactable_unfocused)
			interactable.canceled_interaction.connect(on_interactable_unfocused)
			
		if grabbable:
			grabbable.focused.connect(on_interactable_focused)
			grabbable.unfocused.connect(on_interactable_unfocused)
	

func apply() -> void:
	for target_mesh: MeshInstance3D in target_meshes:
		var material: StandardMaterial3D = target_mesh.get_active_material(0)
		
		if material == null:
			material = target_mesh.get_surface_override_material(0)
		
		match outline_mode:
			OutlineMode.EdgeShader:
				if material and not material.next_pass:
				
					if outline_edge_shader_material == null:
						outline_edge_shader_material = ShaderMaterial.new()
						outline_edge_shader_material.shader = PixelPerfectShader
						
					outline_edge_shader_material.set_shader_parameter("outline_color", outline_color)
					outline_edge_shader_material.set_shader_parameter("outline_width", outline_width)
					material.next_pass = outline_edge_shader_material
				
			OutlineMode.InvertedHull:
				if outline_hull_material == null:
					outline_hull_material = StandardMaterial3D.new()
					outline_hull_material.grow = true
					outline_hull_material.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
					outline_hull_material.cull_mode = BaseMaterial3D.CULL_FRONT
					outline_hull_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				
				outline_hull_material.albedo_color = outline_hull_color
				outline_hull_material.grow_amount = outline_grow_amount
				target_mesh.material_overlay = outline_hull_material


func remove() -> void:
	for target_mesh: MeshInstance3D in target_meshes:
		var material: StandardMaterial3D = target_mesh.get_active_material(0)
		
		if material == null:
			material = target_mesh.get_surface_override_material(0)
			
		match outline_mode:
			OutlineMode.EdgeShader:
				if material:
					material.next_pass = null
			OutlineMode.InvertedHull:
				target_mesh.material_overlay = null


func on_interactable_focused() -> void:
	apply()


func on_interactable_unfocused() -> void:
	remove()
