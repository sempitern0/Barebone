@tool
class_name Planet3D extends MeshInstance3D

const GroupName: StringName = &"planets"

@export var configuration: PlanetConfiguration:
	set(new_configuration_value):
		_connect_configuration_listener(new_configuration_value)
		configuration = new_configuration_value

@export var atmosphere: MeshInstance3D


func _enter_tree() -> void:
	add_to_group(GroupName)
	_connect_configuration_listener(configuration)
	
	update_parameters()
	update_atmosphere()


func update_parameters() -> void:
	if mesh:
		mesh.radial_segments = configuration.resolution
		mesh.rings = configuration.resolution
		mesh.radius = configuration.radius
		mesh.height = mesh.radius * 2.0
		
	if atmosphere and atmosphere.mesh:
		atmosphere.mesh.radial_segments = configuration.resolution
		atmosphere.mesh.rings = configuration.resolution
		atmosphere.mesh.radius = configuration.radius
		atmosphere.mesh.height = atmosphere.mesh.radius * 2.0


func update_atmosphere() -> void:
	if atmosphere:
		if configuration.atmosphere:
			atmosphere.process_mode = Node.PROCESS_MODE_PAUSABLE
			atmosphere.show()
		else:
			atmosphere.process_mode = Node.PROCESS_MODE_DISABLED
			atmosphere.hide()

		
func _connect_configuration_listener(new_configuration: PlanetConfiguration = null) -> void:	
	if Engine.is_editor_hint():
		if new_configuration:
			if not new_configuration.changed.is_connected(on_configuration_changed):
				new_configuration.changed.connect(on_configuration_changed)
				
		elif configuration and new_configuration == null:
			if configuration.changed.is_connected(on_configuration_changed):
				configuration.changed.disconnect(on_configuration_changed)
				

func on_configuration_changed() -> void:
	update_parameters()
	update_atmosphere()
