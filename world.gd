class_name World extends Node3D

@onready var placeable_manager: PlaceableManager = $PlaceableManager


#func _unhandled_input(_event: InputEvent) -> void:
	#if OmniKitInputHelper.action_just_pressed_and_exists(&"ui_accept"):
		#OmniKitWindowManager.screenshot_to_folder(get_viewport())
