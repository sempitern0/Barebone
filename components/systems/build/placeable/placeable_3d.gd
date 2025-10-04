@icon("res://components/systems/build/placeable/placeable.svg")
class_name Placeable3D extends Node3D

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var target: Node3D
@export var placement_area: PlacementArea3D
@export var height_offset: float = 0.0
@export var drag_mode: DragMode = DragMode.Manual
@export_category("Camera")
@export var origin_camera: Camera3D
@export var drag_distance_from_camera: float = 50.0

enum DragMode {
	ClickToDrag, ## Keep pressed the collisionable to drag it
	Manual ## Change manually via code the "placing" variable to activate the drag
}

var placing: bool = false:
	set(value):
		if placing != value:
			placing = value
			set_physics_process(placing)
			
			
func _ready() -> void:
	assert(target != null and target is Node3D, "Placeable3D: This placeable does not have a target Node3D assigned")

	if origin_camera == null:
		origin_camera = get_viewport().get_camera_3d()
	
	if placing:
		placement_area.call_deferred("enable")
	else:
		placement_area.call_deferred("disable")
		
	set_process_unhandled_input(placing)
	set_physics_process(placing)
