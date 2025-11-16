@tool
class_name Planet3D extends MeshInstance3D

const GroupName: StringName = &"planets"

@export_tool_button("Generate") var generate_planet: Callable = generate
@export var configuration: PlanetConfiguration:
	set(new_configuration_value):
		_connect_configuration_listener(new_configuration_value)
		configuration = new_configuration_value

@export var atmosphere: MeshInstance3D


func _enter_tree() -> void:
	add_to_group(GroupName)
	_connect_configuration_listener(configuration)
	

func generate() -> void:
	pass


func update_atmosphere() -> void:
	if atmosphere and configuration.atmosphere:
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
	update_atmosphere()
