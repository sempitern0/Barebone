@icon("res://components/2D/interactions/interactor/interactor_2d.svg")
class_name AreaInteractor2D extends Area2D

@export var maximum_detection_distance: float = 25.0


var current_interactable: Interactable2D
var focused: bool = false
var interacting: bool = false


func _unhandled_input(_event: InputEvent):
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.Interact) \
		and current_interactable \
		and not interacting:
			
		interact(current_interactable)
		
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.CancelInteraction) and current_interactable:
		cancel_interact(current_interactable)


func _enter_tree():
	priority = 1
	collision_layer = 0
	collision_mask = Globals.world_collision_layer | Globals.interactables_collision_layer | Globals.grabbables_collision_layer
	monitoring = true
	monitorable = false


func _physics_process(_delta):
	var detected_interactables = get_overlapping_areas()\
		.filter(func(area: Area2D): return area is Interactable2D)
		
	detected_interactables = OmniKitNodePositioner.get_nearest_nodes_sorted_by_distance_v2(global_position, detected_interactables, 0.0, maximum_detection_distance)
	
	if detected_interactables.size() > 0:
		if current_interactable == null and not focused:
			focus(detected_interactables.front())
	else:
		if focused and not interacting and current_interactable:
			
			unfocus(current_interactable)


func interact(interactable: Interactable2D = current_interactable):
	if interactable and not interacting:
		interacting = interactable.lock_player_on_interact
		
		interactable.interacted.emit()
		GlobalEvents.interactable_2d_interacted.emit(interactable)


func cancel_interact(interactable: Interactable2D = current_interactable):
	if interactable:
		interacting = false
		focused = false
		current_interactable = null
		
		interactable.canceled_interaction.emit()
		GlobalEvents.interactable_2d_canceled_interaction.emit(interactable)


func focus(interactable: Interactable2D):
	current_interactable = interactable
	focused = true
	
	interactable.focused.emit()
	GlobalEvents.interactable_2d_focused.emit(interactable)


func unfocus(interactable: Interactable2D = current_interactable):
	if interactable and focused:
		current_interactable = null
		focused = false
		interacting = false
		
		interactable.unfocused.emit()
		GlobalEvents.interactable_2d_unfocused.emit(interactable)
