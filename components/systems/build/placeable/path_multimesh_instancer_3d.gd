@tool
## This path can be used on both editor and runtime to instance meshes along a path with the power of MultiMeshInstance
## Make sure the MultiMesh have the transform_format property on TransformFormat.3D
class_name PathMultiMeshInstancer3D extends Path3D

@export var point_offset: Vector3 = Vector3.ZERO
@export var distance_between_meshes: float = 1.0:
	set(value):
		if distance_between_meshes != value:
			distance_between_meshes = value
			_update_multimesh()
@export var multimesh_instance: MultiMeshInstance3D


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		if not curve_changed.is_connected(_on_curve_changed):
			curve_changed.connect(_on_curve_changed)


func _ready():
	if not curve_changed.is_connected(_on_curve_changed):
		curve_changed.connect(_on_curve_changed)


func add_point(point: Vector3, use_height: bool = false) -> void:
	if not use_height:
		point_offset.y = 0

	curve.add_point(Vector3(point.x, point.y if use_height else 0.0, point.z) + point_offset)


func remove_last_point() -> void:
	if curve.point_count > 0:
		curve.remove_point(curve.point_count - 1)
		

func clear() -> void:
	curve.clear()
	
	
func assign_mesh(mesh: Mesh) -> void:
	if multimesh_instance:
		multimesh_instance.multimesh.mesh = mesh


func _update_multimesh():
	if multimesh_instance and multimesh_instance.multimesh:
		var path_length: float = curve.get_baked_length()
		var count: int = floori(path_length / distance_between_meshes)

		multimesh_instance.multimesh.instance_count = count
		var offset = distance_between_meshes / 2.0
		
		for i in range(0, count):
			var curve_distance = offset + distance_between_meshes * i
			@warning_ignore("shadowed_variable_base_class")
			var position = curve.sample_baked(curve_distance, true) ## If I use other name for the variable it doesnt work

			var up = curve.sample_baked_up_vector(curve_distance, true)
			var forward = position.direction_to(curve.sample_baked(curve_distance + 0.1, true))
			
			var final_basis: Basis = Basis(up, forward.cross(up).normalized(), -forward)
			var final_transform = Transform3D(final_basis, position)
			
			multimesh_instance.multimesh.set_instance_transform(i, final_transform)


func _on_curve_changed():
	_update_multimesh()
