@tool
class_name Scatter3D
extends MultiMeshInstance3D

enum ScatterShapeType { Box, Sphere }
enum InstanceMethod { RandomRejection, PoissonDiskSampling }

@export var mesh_instance: MeshInstance3D
@export var scatter_shape: ScatterShapeType = ScatterShapeType.Sphere:
	set(value):
		scatter_shape = value
		scatter()
@export var count: int = 100:
	set(value):
		if count != value:
			count = maxi(1, value)
			scatter()
@export_range(0.1, 10000.0, 0.1) var min_distance_between: float = 1.0:
	set(value):
		if min_distance_between != value:
			min_distance_between = value
			scatter()
@export var instance_method: InstanceMethod = InstanceMethod.RandomRejection:
	set(value):
		if instance_method != value:
			instance_method = value
			scatter()
## Attemps to calculate the placement when using the current instance method
@export_range(1, 10, 1) var max_attempts_per_instance: int = 5:
	set(value):
		if value != max_attempts_per_instance:
			max_attempts_per_instance = value
			scatter()
@export var scatter_size: Vector3 = Vector3(10.0, 10.0, 10.0):
	set(value):
		if not value.is_equal_approx(scatter_size):
			scatter_size = value.clamp(Vector3.ONE * 0.01, Vector3.ONE * 10000.0)
			scatter()
@export_flags_3d_physics var collision_masks: int = 1


#func _notification(what: int) -> void:
	#if what == NOTIFICATION_TRANSFORM_CHANGED:
		#scatter()


func _ready() -> void:
	if not Engine.is_editor_hint():
		set_notify_transform(false)
		set_ignore_transform_notification(true)
	

func scatter(method: InstanceMethod = instance_method) -> void:
	if not _prepare_multimesh():
		push_error("[MultiMeshScatter]: The Scatter3D doesn't have an assigned mesh, aborting the operation.")
		return
		
	match method:
		InstanceMethod.RandomRejection:
			random_rejection_scatter()
		InstanceMethod.PoissonDiskSampling:
			poisson_disk_sampling_scatter()


func poisson_disk_sampling_scatter() -> void:
	var domain_size = Vector2(scatter_size.x, scatter_size.z)
	var poisson_points: Array[Vector2] = poisson_disk_points_2d(
		domain_size, 
		min_distance_between
	)
	
	var final_points: Array[Vector2] = []

	match scatter_shape:
		ScatterShapeType.Sphere:
			var half_size: float = scatter_size.x / 2.0
			var radius_squared: float = half_size * half_size
			var center_2d: Vector2 = domain_size / 2.0
			
			for point_2d in poisson_points:
				# Distancia del punto al centro del dominio (dominio 0,0 a size.x, size.z)
				if point_2d.distance_squared_to(center_2d) <= radius_squared:
					final_points.append(point_2d)
					
		ScatterShapeType.Box:
			final_points = poisson_points
			
	multimesh.instance_count = mini(final_points.size(), count)
	
	for i in range(multimesh.instance_count):
		var point_2d: Vector2 = final_points[i]
		var target_position_centered: Vector3 = _poisson_point_2d_to_3d(point_2d)

		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			target_position_centered + Vector3.UP * (scatter_size.y / 2.0),
			target_position_centered + Vector3.DOWN * (scatter_size.y / 2.0),
			collision_masks
		)
			
		var hit: OmniKitRaycastResult = OmniKitRaycastResult.new(get_world_3d().direct_space_state.intersect_ray(ray))
		
		if hit.position:
			var final_transform = Transform3D(Basis(), hit.position - global_position)
			multimesh.set_instance_transform(i, final_transform)


func random_rejection_scatter() -> void:
	var placed_positions: Array[Vector3] = []

	for i in range(count):
		var attempts: int = 0
		var valid: bool = false
		var target_position: Vector3

		while attempts < max_attempts_per_instance and not valid:
			attempts += 1
			
			match scatter_shape:
				ScatterShapeType.Sphere:
					var radius: float = sqrt(randf()) * (scatter_size.x / 2.0)
					var theta: float = randf_range(0.0, TAU)
					target_position = global_position + Vector3(radius * cos(theta), 0.0, radius * sin(theta))
				
				ScatterShapeType.Box:
					target_position = global_position + Vector3(
						randf_range(-scatter_size.x / 2.0, scatter_size.x / 2.0),
						0.0,
						randf_range(-scatter_size.z / 2.0, scatter_size.z / 2.0)
					)
				_:
					target_position = global_position

			valid = true
			
			for prev: Vector3 in placed_positions:
				if prev.distance_squared_to(target_position) < min_distance_between * min_distance_between:
					valid = false
					placed_positions.erase(prev)
					break
		if valid:
			placed_positions.append(target_position)
	
	multimesh.instance_count = mini(count, placed_positions.size())
	
	for i in multimesh.instance_count:
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			placed_positions[i] + Vector3.UP * (scatter_size.y / 2.0),
			placed_positions[i] + Vector3.DOWN * (scatter_size.y / 2.0),
			collision_masks
		)
			
		var hit: OmniKitRaycastResult = OmniKitRaycastResult.new(get_world_3d().direct_space_state.intersect_ray(ray))
		
		if hit.position:
			multimesh.set_instance_transform(i, Transform3D(Basis(), hit.position - global_position))


func poisson_disk_points_2d(size: Vector2, radius: float, attempts: float = 5) -> Array[Vector2]:
	var cell_size = radius / sqrt(2)
	var grid = {}
	var points: Array[Vector2] = []
	var active: Array[Vector2] = []

	var first = Vector2(randf() * size.x, randf() * size.y)
	points.append(first)
	active.append(first)
	grid[Vector2i(first / cell_size)] = first

	while active.size() > 0:
		var idx: int = randi_range(0, active.size() - 1)
		var base: Vector2 = active[idx]
		var found: bool = false

		for _i in range(attempts):
			var angle: float = randf() * TAU
			var dist: float = randf_range(radius, 2 * radius)
			var candidate: Vector2 = base + Vector2(cos(angle), sin(angle)) * dist

			if candidate.x < 0 or candidate.y < 0 or candidate.x > size.x or candidate.y > size.y:
				continue

			var cell = Vector2i(candidate / cell_size)
			var ok: bool = true
			
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var neighbor = grid.get(cell + Vector2i(dx, dy))
					if neighbor and neighbor.distance_to(candidate) < radius:
						ok = false
						break
						
				if not ok:
					break

			if ok:
				points.append(candidate)
				active.append(candidate)
				grid[cell] = candidate
				found = true
				break

		if not found:
			active.remove_at(idx)

	return points


func _poisson_point_2d_to_3d(point: Vector2) -> Vector3:
	return global_position + Vector3(point.x - scatter_size.x /2, 0, point.y - scatter_size.z / 2)


func _prepare_multimesh() -> bool:
	if multimesh == null:
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		
	if mesh_instance:
		multimesh.mesh = mesh_instance.mesh
		
	return multimesh.mesh != null
