@icon("res://components/systems/build/placeable/icons/placeable.svg")
class_name Placeable3D extends Node3D

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var placement_area: PlacementArea3D
@export var placement_offset: Vector3 = Vector3.ZERO
@export var snap_enabled: bool = false 
@export var snap_step: Vector3 = Vector3(1.0, 0, 1.0)
@export var snap_offset: Vector3 = Vector3.ZERO 
@export var drag_mode: DragMode = DragMode.Manual
@export_category("Camera")
@export var origin_camera: Camera3D
@export var drag_distance_from_camera: float = 50.0
@export_category("Materials")
@export var use_validation_materials: bool = true
@export var valid_place_material: StandardMaterial3D 
@export var invalid_place_material: StandardMaterial3D


enum DragMode {
	ClickToDrag, ## Keep pressed the collisionable to drag it
	Manual ## Change manually via code the "placing" variable to activate the drag
}

var placement_is_valid: bool = false
var placing: bool = false:
	set(value):
		if placing != value:
			placing = value
			set_physics_process(placing)
			call_deferred("apply_placement_validation_material", placement_is_valid)
			
var excluded_rids: Array[RID] = []
var meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	if origin_camera == null:
		origin_camera = get_viewport().get_camera_3d()
	
	if placing:
		placement_area.call_deferred("enable")
	else:
		placement_area.call_deferred("disable")
		
	_update_collisionables()
	_update_meshes()
	
	set_process_unhandled_input(placing)
	set_physics_process(placing)


func _physics_process(_delta: float) -> void:
	handle_drag_motion()
	
	
func handle_drag_motion():
	if origin_camera and placing:
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		
		var world_space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var from: Vector3 = origin_camera.project_ray_origin(mouse_position)
		var to: Vector3 = origin_camera.project_position(mouse_position, drag_distance_from_camera)
		
		var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		ray_query.exclude = excluded_rids
	
		ray_query.collide_with_areas = false
		ray_query.collide_with_bodies = true
		
		var result: Dictionary = world_space.intersect_ray(ray_query)
		
		if result.has("position"):
			var target_position: Vector3 = result.position
			
			if snap_enabled:
				var snapped_position: Vector3 = (target_position - snap_offset).snapped(snap_step) + snap_offset
				
				if snap_step.y == 0:
					snapped_position.y = target_position.y
					
				global_position = snapped_position
			else:
				global_position = target_position
				
			global_position += placement_offset


func apply_placement_validation_material(valid: bool = placement_is_valid) -> void:
	if (valid_place_material and valid) or (not valid and invalid_place_material):
		for mesh: MeshInstance3D in meshes:
			mesh.set_surface_override_material(0, valid_place_material if valid else invalid_place_material)
		

func remove_placement_validation_material() -> void:
	if use_validation_materials:
		for mesh: MeshInstance3D in meshes:
			mesh.set_surface_override_material(0, null)
		

func _update_collisionables() -> void:
	excluded_rids.clear()
	
	for child: Node in OmniKitNodeTraversal.get_all_children(self):
		if child is CollisionObject3D:
			excluded_rids.append(child.get_rid())
			
			
func _update_meshes() -> void:
	meshes.clear()
	
	for child: Node in OmniKitNodeTraversal.get_all_children(self):
		if child is MeshInstance3D:
			meshes.append(child)
