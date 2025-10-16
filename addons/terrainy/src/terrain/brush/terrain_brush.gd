## Brush to modify the terrain on runtime
class_name TerrainBrush extends Node3D

@export var origin_camera: Camera3D:
	set(new_camera):
		origin_camera = new_camera
		
		if is_node_ready():
			set_process(origin_camera != null)
			set_process_unhandled_input(origin_camera != null)
			
@export_range(0.1, 100.0, 0.1) var brush_radius: float = 15.0
@export_range(0.1, 10, 0.1) var brush_strength: float = 1.5


enum Modes {
	RaiseTerrain,
	LowerTerrain
}

var painting: bool = false
var current_mode: Modes = Modes.RaiseTerrain


func _unhandled_input(_event: InputEvent) -> void:
	painting = OmniKitInputHelper.action_pressed_and_exists(InputControls.PaintTerrain)


func _ready() -> void:
	set_process(origin_camera != null)
	set_process_unhandled_input(origin_camera != null)


func _process(_delta: float) -> void:
	if painting:
		var result: OmniKitRaycastResult = OmniKitCamera3DHelper.project_raycast_to_mouse(origin_camera, 500.0, Globals.world_collision_layer)
		
		if result.position and result.collider:
			match current_mode:
				Modes.RaiseTerrain:
					deform_terrain(
						result.collider.get_parent(), 
						result.position, 
						brush_radius, brush_strength)
						
				Modes.LowerTerrain:
					deform_terrain(
						result.collider.get_parent(), 
						result.position, 
						brush_radius, 
						brush_strength * -1.0
					)
		
func deform_terrain(terrain: Terrain, point: Vector3, radius: float = brush_radius, strength: float = brush_strength) -> void:
	if terrain.mesh == null:
		return

	var mdt: MeshDataTool = MeshDataTool.new()
	mdt.create_from_surface(terrain.mesh, 0)
	
	var local_point: Vector3 = terrain.to_local(point)
	var radius_sq: float = radius * radius  

	for vertex_index: int in mdt.get_vertex_count():
		var vertex: Vector3 = mdt.get_vertex(vertex_index)
		var dist_sq: float = vertex.distance_squared_to(local_point)

		if dist_sq < radius_sq:
			var falloff: float = 1.0 - (dist_sq / radius_sq)
			falloff = falloff * falloff
			
			vertex.y += strength * falloff
			mdt.set_vertex(vertex_index, vertex)
	
	var array_mesh: ArrayMesh = ArrayMesh.new()
	mdt.commit_to_surface(array_mesh)
	terrain.mesh = array_mesh


func change_mode_to(new_mode: Modes) -> void:
	current_mode = new_mode
	
	
func change_mode_to_raise_terrain() -> void:
	change_mode_to(Modes.RaiseTerrain)


func change_mode_to_lower_terrain() -> void:
	change_mode_to(Modes.LowerTerrain)
