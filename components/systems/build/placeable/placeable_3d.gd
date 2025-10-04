@icon("res://components/systems/build/placeable/placeable.svg")
class_name Placeable3D extends Node3D

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var target: Node3D
@export var placement_area: PlacementArea3D
## Internal collisionable objects to be excluded on the ray query to drag in the world
@export var collisionables: Array[CollisionObject3D] = []
@export var offset: Vector3 = Vector3.ZERO
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

	handle_drag_motion()

	
func handle_drag_motion():
	if origin_camera and placing:
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		
		var world_space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var from: Vector3 = origin_camera.project_ray_origin(mouse_position)
		var to: Vector3 = origin_camera.project_position(mouse_position, drag_distance_from_camera)
		
		var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		ray_query.exclude = collisionables.map(
			func(collisionable: CollisionObject3D): return collisionable.get_rid()
		)
	
		ray_query.collide_with_areas = false
		ray_query.collide_with_bodies = true
		
		var result: Dictionary = world_space.intersect_ray(ray_query)
	
		if result.has("position"):
			target.global_position = result.position
			target.global_position += offset
