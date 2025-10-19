@icon("res://components/systems/build/placeable/icons/placeable.svg")
class_name Placeable3D extends Node3D

const GroupName: StringName = &"placeables"

signal placed()
signal placement_started
signal placement_canceled
signal placement_requested

## This node can be a child of the target using composition so assign it here.
@export var target: Node3D
@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export_category("Placement")
@export var placement_area: PlacementArea3D
@export var placement_offset: Vector3 = Vector3.ZERO
## Value 1 block the axis when placing
@export var axis_lock: Vector3 = Vector3.ZERO
@export var align_with_surface_normal: bool = false
@export var can_be_repositioned: bool = true
## Set to zero to have no limit of this placeable in the world
@export var limit_in_the_world: int = 0
@export_range(0.0, 180.0, 0.01, "radians_as_degrees") var max_align_surface_normal_angle: float
@export_category("Snap")
@export var snap_enabled: bool = false 
@export var snap_step: Vector3 = Vector3(1.0, 0, 1.0)
@export var snap_offset: Vector3 = Vector3.ZERO 
@export_category("Rotation")
@export var can_be_rotated: bool = true
## Apply the entire rotation when the action input to rotate is pressed.
@export var direct_input_rotation: bool = false 
## When direct_input_rotation is false, this defines the radian rotation per second to apply in the placeable as is frame rate independent.
@export_range(0.0, 180.0, 0.01, "radians_as_degrees") var rotation_step: float
@export_category("Materials")
@export var valid_place_material: StandardMaterial3D 
@export var invalid_place_material: StandardMaterial3D


## Variable to lock this placeable once is placed on the world
var locked: bool = false
var placing: bool = false:
	set(value):
		if placing != value:
			placing = value
			
			if placing:
				placement_area.enable()
			else:				
				remove_placement_validation_material()
				placement_area.disable()
				
			set_physics_process(placing)
	
var excluded_rids: Array[RID] = []
var meshes: Array[MeshInstance3D] = []
var last_transform: Transform3D
var new: bool = true

var original_meshes_materials: Dictionary[MeshInstance3D, Material] = {}


func _enter_tree() -> void:
	add_to_group(GroupName)


func _ready() -> void:
	if target == null:
		target = self
		
	if placing:
		placement_area.enable()
	else:
		placement_area.disable()
		
	_update_collisionables()
	_update_meshes()
	
	set_physics_process(placing)
	
	placement_area.selected.connect(on_placement_area_selected)
	placement_started.connect(on_placement_started)
	placement_canceled.connect(on_placement_canceled)
	placed.connect(on_placed)


func _physics_process(_delta: float) -> void:
	apply_placement_validation_material()

	
func is_valid() -> bool:
	return placement_area.is_valid()


func apply_placement_validation_material(valid: bool = placement_area.placement_is_valid) -> void:
	if meshes.size():
		if valid_place_material and valid:
			for mesh: MeshInstance3D in meshes:
				mesh.material_override = valid_place_material
		
		elif not valid and invalid_place_material: 
			for mesh: MeshInstance3D in meshes:
				mesh.material_override = invalid_place_material
		

func remove_placement_validation_material() -> void:
	for mesh: MeshInstance3D in meshes:
		mesh.material_override = original_meshes_materials.get(mesh, null)
	
	
func lock() -> void:
	locked = true

	
func unlock() -> void:
	locked = false


func _update_collisionables() -> void:
	excluded_rids.clear()
	
	for child: Node in OmniKitNodeTraversal.get_all_children(target):
		if child is CollisionObject3D:
			excluded_rids.append(child.get_rid())
			
			
func _update_meshes() -> void:
	meshes.clear()
	
	for child: Node in OmniKitNodeTraversal.get_all_children(target):
		if child is MeshInstance3D:
			original_meshes_materials[child as MeshInstance3D] = child.material_override
			meshes.append(child)


func on_placement_area_selected() -> void:
	if can_be_repositioned and not placing and not locked:
		placement_requested.emit()


func on_placed() -> void:
	last_transform = target.global_transform
	placing = false
	
	if can_be_repositioned:
		await Globals.wait(0.2)
		placement_area.make_selectable(true)
	else:
		placement_area.make_selectable(false)


func on_placement_started() -> void:
	placement_area.make_selectable(false)
	

func on_placement_canceled() -> void:
	if last_transform:
		target.global_transform = last_transform
		await Globals.wait(0.2)
		placement_area.make_selectable(true)
	else:
		target.queue_free()
	
	placing = false
