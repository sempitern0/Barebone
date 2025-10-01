@tool
extends EditorPlugin


const PoolNodeName: String = "FastPool"
const PoolManager: String = "FastPoolManager"

func _enter_tree() -> void:
	add_custom_type(
		PoolNodeName,
		"Node",
		preload("src/object_pool.gd"),
		preload("src/object_pool.svg")
	)
	
	add_autoload_singleton(PoolManager, "src/object_pool_manager.gd")


func _exit_tree() -> void:
	remove_autoload_singleton(PoolManager)
	remove_custom_type(PoolNodeName)
