@icon("res://components/3D/interactions/interactors/icons/interactor.svg")
class_name AreaInteractor3D extends Area3D

@export var maximum_detection_distance: float = 3
@export var interact_input_action: StringName = &"interact"
@export var cancel_interact_input_action: StringName = &"cancel_interact"

var detected_interactables: Array[Interactable3D] = []
var current_interactable: Interactable3D


func _unhandled_input(_event: InputEvent):
	if current_interactable:
		if OmniKitInputHelper.action_just_pressed_and_exists(interact_input_action):
			interact(current_interactable)
			
		elif OmniKitInputHelper.action_just_pressed_and_exists(cancel_interact_input_action):
			cancel_interact(current_interactable)
			

func _enter_tree():
	priority = 1
	collision_layer = 0
	collision_mask = Globals.world_collision_layer | Globals.interactables_collision_layer 
	monitoring = true
	monitorable = false
	

func _physics_process(_delta: float) -> void:
	if monitoring and Engine.get_physics_frames() % 10 == 0:
		update_interactables()
	
		var new_interactable: Interactable3D = null if detected_interactables.is_empty() else detected_interactables.front()
		
		if current_interactable != new_interactable:
			if is_instance_valid(current_interactable):
				unfocus(current_interactable)
			if is_instance_valid(new_interactable):
				current_interactable = new_interactable
				focus(new_interactable)


func update_interactables() -> void:
	detected_interactables.assign(get_overlapping_areas()\
		.filter(func(area: Area3D): return area is Interactable3D))
	
	detected_interactables = OmniKitNodePositioner.get_nearest_nodes_sorted_by_distance_v3(
		global_position, 
		detected_interactables, 
		0.0, maximum_detection_distance
		)
		
	
func interact(interactable: Interactable3D):
	if interactable and interactable.can_be_interacted:
		set_deferred("current_interactable", null)
		
		interactable.interacted.emit()
		

func cancel_interact(interactable: Interactable3D):
	if interactable:
		set_deferred("current_interactable", null)
		
		interactable.canceled_interaction.emit()


func focus(interactable: Interactable3D):
	if interactable:
		interactable.focused.emit()
		GlobalEvents.interactable_3d_focused.emit(interactable)


func unfocus(interactable: Interactable3D):
	if interactable:
		detected_interactables.erase(interactable)
		interactable.unfocused.emit()
