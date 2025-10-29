@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("ConnectaPuzzle", "Node2D", preload("src/connecta_puzzle.gd"), preload("assets/puzzle.svg"))


func _exit_tree() -> void:
	remove_custom_type("ConnectaPuzzle")
