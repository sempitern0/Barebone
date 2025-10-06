@icon("res://components/systems/build/placeable/icons/placeable.svg")
class_name Placeable3D extends Node3D

signal placed
signal placement_started
signal placement_canceled

## This node can be a child of the target using composition so assign it here.
@export var target: Node3D
@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export_category("Camera")
@export var origin_camera: Camera3D
@export var drag_distance_from_camera: float = 50.0
@export_category("Placement")
@export var placement_area: PlacementArea3D
@export var placement_offset: Vector3 = Vector3.ZERO
@export var align_with_surface_normal: bool = false
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
@export var use_validation_materials: bool = true
@export var valid_place_material: StandardMaterial3D 
@export var invalid_place_material: StandardMaterial3D


## Variable to lock this placeable once is placed on the world
var locked: bool = false
var placing: bool = false:
	set(value):
		if locked:
			return
			
		if placing != value:
			var previous_placing: bool = placing
			placing = value
			
			if previous_placing and not placing:
				placed.emit()
			else:
				placement_area.make_selectable(false)
				
			if placing:
				placement_area.enable()
				placement_started.emit()
			else:
				placement_area.disable()
				remove_placement_validation_material()
				
			set_process_input(placing)
			set_physics_process(placing)
	

var excluded_rids: Array[RID] = []
var meshes: Array[MeshInstance3D] = []
var last_transform: Transform3D
var surface_normal: Vector3 = Vector3.UP


func _unhandled_input(_event: InputEvent) -> void:
	if placement_area.placement_is_valid and OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ConfirmPlacement):
		last_transform = global_transform
		placing = false
	
	elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.CancelPlacement):
		placing = false
		placement_canceled.emit()
		
		if last_transform:
			global_transform = last_transform
		else:
			queue_free()

	if placing and direct_input_rotation:
		if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.RotateLeft):
			rotation.y += rotation_step
		elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.RotateRight):
			rotation.y -= rotation_step


func _ready() -> void:
	if origin_camera == null:
		origin_camera = get_viewport().get_camera_3d()
	
	if target == null:
		target = self
		
		
	if placing:
		placement_area.enable()
	else:
		placement_area.disable()
		
	_update_collisionables()
	_update_meshes()
	
	set_process_input(placing)
	set_physics_process(placing)
	
	placement_area.selected.connect(on_placement_area_selected)
	placed.connect(on_placed)


func _physics_process(delta: float) -> void:
	handle_drag_motion()
	
	if not direct_input_rotation:
		handle_rotation(delta)
	
	apply_placement_validation_material()
	
	
func handle_drag_motion():
	if origin_camera and placing:
		var world_projection_result: OmniKitRaycastResult = world_projected_position()
		surface_normal = world_projection_result.normal if world_projection_result.normal else Vector3.UP
		
		if world_projection_result.position:
			var target_position: Vector3 = world_projection_result.position
			
			if align_with_surface_normal:
				global_transform.basis = align_placeable_with_surface_normal(world_projection_result).basis
			
			if placement_offset.y != 0:
			# Move along the surface normal by the height offset amount
				var offset_vector = surface_normal.normalized() * placement_offset.y
				target_position += offset_vector
			
			global_position = target_position
			
			if snap_enabled:
				var snapped_position: Vector3 = (target_position - snap_offset).snapped(snap_step) + snap_offset
				
				if snap_step.y == 0:
					snapped_position.y = target_position.y
					
				global_position = snapped_position
				
			global_position += placement_offset


func handle_rotation(delta: float = get_physics_process_delta_time()) -> void:
	if can_be_rotated and rotation_step > 0:
		if OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateLeft):
			rotation.y += rotation_step * delta
				
		elif OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateRight):
			rotation.y -= rotation_step * delta


func world_projected_position() -> OmniKitRaycastResult:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
		
	var world_space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = origin_camera.project_ray_origin(mouse_position)
	var to: Vector3 = origin_camera.project_position(mouse_position, drag_distance_from_camera)
	
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	ray_query.exclude = excluded_rids
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	
	var result: Dictionary = world_space.intersect_ray(ray_query)
	
	return OmniKitRaycastResult.new(result)


func align_placeable_with_surface_normal(world_projection_result: OmniKitRaycastResult) -> Transform3D:
	var target_position: Vector3 = world_projection_result.position
	var xform: Transform3D = global_transform
	
	surface_normal = world_projection_result.normal if world_projection_result.normal else Vector3.UP
	var angle_to_up: float = surface_normal.angle_to(Vector3.UP)

	if max_align_surface_normal_angle > 0 and angle_to_up > max_align_surface_normal_angle:
		surface_normal = Vector3.UP.slerp(surface_normal, max_align_surface_normal_angle / angle_to_up).normalized()
	
	xform = xform.looking_at(
		target_position + -xform.basis.z.slide(Vector3.UP).normalized(), 
		surface_normal 
	)
	
	var up: Vector3 = xform.basis.y.normalized()
	var right: Vector3 = xform.basis.x.normalized()

	var forward: Vector3 = -global_transform.basis.z
	forward = (forward - up * forward.dot(up)).normalized()
	right = up.cross(forward).normalized()
	
	xform.basis = Basis(right, up, -forward).orthonormalized()

	return xform
	
func apply_placement_validation_material(valid: bool = placement_area.placement_is_valid) -> void:
	if meshes.size():
		
		if valid_place_material and valid:
			for mesh: MeshInstance3D in meshes:
				mesh.set_surface_override_material(0, valid_place_material)
		
		elif not valid and invalid_place_material: 
			for mesh: MeshInstance3D in meshes:
				mesh.set_surface_override_material(0, invalid_place_material)
		

func remove_placement_validation_material() -> void:
	for mesh: MeshInstance3D in meshes:
		mesh.set_surface_override_material(0, null)
	
	
func lock() -> void:
	locked = true

	
func unlock() -> void:
	locked = false


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


func on_placement_area_selected() -> void:
	placing = true
	
	
func on_placed() -> void:
	await Globals.wait(0.2)
	placement_area.make_selectable(true)
