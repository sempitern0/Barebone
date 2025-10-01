@tool
extends EditorPlugin

const PluginName: String = "VaultSaveManager"

func _enter_tree() -> void:
	add_autoload_singleton(PluginName, "src/save_manager.gd")
	

func _exit_tree() -> void:
	remove_autoload_singleton(PluginName)
