@tool
extends EditorPlugin

const PluginName: String = "EasyCamSwitch"

func _enter_tree() -> void:
	add_autoload_singleton(PluginName, "src/easy_cam_switch.tscn" )


func _exit_tree() -> void:
	remove_autoload_singleton(PluginName)
