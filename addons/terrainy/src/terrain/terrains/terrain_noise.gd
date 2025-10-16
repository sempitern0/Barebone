@tool
class_name TerrainNoise extends Terrain

@export var configuration: TerrainNoiseConfiguration


func validate() -> bool:
	return configuration.noise != null


func generate_surface() -> SurfaceTool:
	var surface: SurfaceTool = SurfaceTool.new()
	var mesh_data_tool: MeshDataTool = MeshDataTool.new()
	
	surface.create_from(mesh, 0)
#
	var array_mesh: ArrayMesh = surface.commit()
	mesh_data_tool.create_from_surface(array_mesh, 0)

	if configuration.randomize_noise_seed:
		configuration.noise.seed = randi()
	
	for vertex_idx: int in mesh_data_tool.get_vertex_count():
		var vertex: Vector3 = mesh_data_tool.get_vertex(vertex_idx)
		## Convert to a range of 0 ~ 1 instead of -1 ~ 1
		var noise_y: float = TerrainyCore.get_noise_y_normalized(configuration.noise, vertex)
		
		if configuration.use_elevation_curve and configuration.elevation_curve:
			if configuration.allow_negative_elevation_values:
				var uv_height_factor = clampf(((vertex.x + vertex.z) / (configuration.size_depth * 2.0)) * 0.5 + 0.5, 0.0, 1.0)
				vertex.y = clampf(vertex.y, -configuration.max_terrain_height, configuration.max_terrain_height)
				
				noise_y = configuration.noise.get_noise_2d(vertex.x, vertex.z) \
					* apply_elevation_curve(configuration, uv_height_factor) \
					* configuration.max_terrain_height
			else:
				noise_y = apply_elevation_curve(configuration, noise_y)
			
		var falloff: float = calculate_falloff(configuration, vertex)
		
		vertex.y = noise_y * configuration.max_terrain_height * falloff
		vertex.y *= apply_radial_shape_on_vertex(configuration, vertex)

		mesh_data_tool.set_vertex(vertex_idx, vertex)
		
	array_mesh.clear_surfaces()
	mesh_data_tool.commit_to_surface(array_mesh)
	
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.create_from(array_mesh, 0)
	surface.generate_normals()
	surface.generate_tangents()

	
	return surface
