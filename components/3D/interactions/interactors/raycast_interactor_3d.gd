@icon("res://components/3D/interactions/interactors/icons/interactor.svg")
class_name RayCastInteractor3D extends RayCast3D

var current_interactable: Interactable3D
var focused: bool = false
var interacting: bool = false


func _unhandled_input(_event: InputEvent):
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.Interact) \
		and current_interactable \
		and not interacting:
			
		interact(current_interactable)
		
	
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.CancelInteraction) \
		and current_interactable:
			
		cancel_interact(current_interactable)
		

func _enter_tree():
	enabled = true
	exclude_parent = true
	collide_with_areas = true
	collide_with_bodies = true
	collision_mask = Globals.world_collision_layer | Globals.interactables_collision_layer


func _physics_process(_delta):
	var detected_interactable = get_collider() if is_colliding() else null

	if detected_interactable is Interactable3D:
		if current_interactable == null and not focused:
			focus(detected_interactable)
	else:
		if focused and not interacting and current_interactable:
			unfocus(current_interactable)


func interact(interactable: Interactable3D = current_interactable):
	if interactable and not interacting and interactable.can_be_interacted:
		enabled = false
		interacting = interactable.lock_player_on_interact
		
		interactable.interacted.emit()
		GlobalEvents.interactable_3d_interacted.emit(interactable)


func cancel_interact(interactable: Interactable3D = current_interactable):
	if interactable:
		interacting = false
		focused = false
		enabled = true
		current_interactable = null
		
		interactable.canceled_interaction.emit()
		GlobalEvents.interactable_3d_canceled_interaction.emit(interactable)


func focus(interactable: Interactable3D):
	current_interactable = interactable
	focused = true
	
	interactable.focused.emit()
	GlobalEvents.interactable_3d_focused.emit(interactable)


func unfocus(interactable: Interactable3D = current_interactable):
	if interactable and focused:
		current_interactable = null
		focused = false
		interacting = false
		enabled = true
		
		interactable.unfocused.emit()
		GlobalEvents.interactable_3d_unfocused.emit(interactable)
