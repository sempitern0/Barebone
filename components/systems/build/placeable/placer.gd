class_name Placer3D extends Node

signal placed(placeable: Placeable3D, repositioned: bool)
signal placement_started(placeable: Placeable3D)
signal placement_canceled(placeable: Placeable3D)
signal placement_invalid(placeable: Placeable3D)


@export var origin_camera: Camera3D
@export var drag_distance_from_camera: float = 100.0

var current_placeable: Placeable3D:
	set(new_placeable):
		if new_placeable != current_placeable:
			current_placeable = new_placeable

			if current_placeable:
				current_placeable.placement_started.emit()
				placement_started.emit(current_placeable)
			else:
				surface_normal = Vector3.UP
				
			set_physics_process(current_placeable != null)
			set_process_unhandled_input(current_placeable != null)

var surface_normal: Vector3 = Vector3.UP


func _unhandled_input(_event: InputEvent) -> void:
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ConfirmPlacement):
		if current_placeable.is_valid():
			place(current_placeable)
		else:
			placement_invalid.emit(current_placeable)
			
	elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.CancelPlacement):
		cancel_placement()
	
	_handle_rotation(current_placeable)


func _ready() -> void:
	if origin_camera == null:
		origin_camera = get_viewport().get_camera_3d()
	
	set_physics_process(current_placeable != null)
	set_process_unhandled_input(current_placeable != null)


func _physics_process(delta: float) -> void:
	_handle_placement(current_placeable)
	
	if not current_placeable.direct_input_rotation:
		_handle_smooth_rotation(current_placeable, delta)


func start_placement(placeable: Placeable3D) -> void:
	cancel_placement()
	current_placeable = placeable
	current_placeable.placing = true


func cancel_placement() -> void:
	if current_placeable:
		placement_canceled.emit(current_placeable)
		current_placeable.placement_canceled.emit()
		current_placeable = null


func place(placeable: Placeable3D = current_placeable) -> void:
	if placeable:
		placeable.placed.emit() 
		placed.emit(placeable, not placeable.new)
		placeable.new = false
		
	current_placeable = null
	

func _handle_placement(placeable: Placeable3D = current_placeable) -> void:
	if placeable:
		var world_projection_result: OmniKitRaycastResult = world_projected_position(origin_camera, placeable.excluded_rids)
		surface_normal = world_projection_result.normal if world_projection_result.normal else Vector3.UP
		
		if world_projection_result.position:
			var target_position: Vector3 = world_projection_result.position
			
			if placeable.align_with_surface_normal:
				placeable.target.global_transform.basis = _align_placeable_with_surface_normal(world_projection_result, current_placeable).basis
			
			if placeable.placement_offset.y != 0:
				# Move along the surface normal by the height offset amount
				var offset_vector = surface_normal.normalized() * placeable.placement_offset.y
				target_position += offset_vector
			
			if placeable.axis_lock.y:
				target_position.y = 0
			
			if placeable.axis_lock.x:
				target_position.x = 0
			
			if placeable.axis_lock.z:
				target_position.z = 0
			
			placeable.target.global_position = target_position
			
			if placeable.snap_enabled:
				var snapped_position: Vector3 = (target_position - placeable.snap_offset).snapped(placeable.snap_step) + placeable.snap_offset
				
				if placeable.snap_step.y == 0:
					snapped_position.y = target_position.y
					
				placeable.target.global_position = snapped_position
				
			placeable.target.global_position += placeable.placement_offset


func _handle_rotation(placeable: Placeable3D = current_placeable) -> void:
	if placeable and placeable.can_be_rotated and placeable.direct_input_rotation:
		if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.RotateLeft):
			placeable.target.rotation.y += placeable.rotation_step
		elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.RotateRight):
			placeable.target.rotation.y -= placeable.rotation_step
			
			
func _handle_smooth_rotation(placeable: Placeable3D = current_placeable, delta: float = get_physics_process_delta_time()) -> void:
	if placeable.can_be_rotated and placeable.rotation_step > 0:
		if OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateLeft):
			placeable.target.rotation.y += placeable.rotation_step * delta
				
		elif OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateRight):
			placeable.target.rotation.y -= placeable.rotation_step * delta


func _align_placeable_with_surface_normal(world_projection_result: OmniKitRaycastResult, placeable: Placeable3D = current_placeable) -> Transform3D:
	var target_position: Vector3 = world_projection_result.position
	var xform: Transform3D = placeable.target.global_transform
	
	surface_normal = world_projection_result.normal if world_projection_result.normal else Vector3.UP
	var angle_to_up: float = surface_normal.angle_to(Vector3.UP)

	if placeable.max_align_surface_normal_angle > 0 and angle_to_up > placeable.max_align_surface_normal_angle:
		surface_normal = Vector3.UP.slerp(surface_normal, placeable.max_align_surface_normal_angle / angle_to_up).normalized()
	
	xform = xform.looking_at(
		target_position + -xform.basis.z.slide(Vector3.UP).normalized(), 
		surface_normal 
	)
	
	var up: Vector3 = xform.basis.y.normalized()
	var right: Vector3 = xform.basis.x.normalized()

	var forward: Vector3 = -current_placeable.target.global_transform.basis.z
	forward = (forward - up * forward.dot(up)).normalized()
	right = up.cross(forward).normalized()
	
	xform.basis = Basis(right, up, -forward).orthonormalized()

	return xform


func world_projected_position(camera: Camera3D = origin_camera, excluded_rids: Array[RID] = []) -> OmniKitRaycastResult:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
		
	var world_space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var from: Vector3 = origin_camera.project_ray_origin(mouse_position)
	var to: Vector3 = origin_camera.project_position(mouse_position, drag_distance_from_camera)
	
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	ray_query.exclude = excluded_rids
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	
	var result: Dictionary = world_space.intersect_ray(ray_query)
	
	return OmniKitRaycastResult.new(result)
