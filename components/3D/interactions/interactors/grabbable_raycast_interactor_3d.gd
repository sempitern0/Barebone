@icon("res://components/3D/interactions/interactors/icons/interactor.svg")
class_name GrabbableRayCastInteractor3D extends RayCast3D

var current_grabbable: Grabbable3D
var focused: bool = false
var interacting: bool = false


func _enter_tree():
	enabled = true
	exclude_parent = true
	collide_with_areas = true
	collide_with_bodies = true
	collision_mask = Globals.world_collision_layer | Globals.interactables_collision_layer | Globals.grabbables_collision_layer

func _physics_process(_delta):
	var detected_grabbable = get_collider() if is_colliding() else null

	if detected_grabbable is Grabbable3D:
		if current_grabbable == null and not focused:
			focus(detected_grabbable)
	else:
		if focused and not interacting and current_grabbable:
			unfocus(current_grabbable)


func focus(grabbable: Grabbable3D):
	current_grabbable = grabbable
	focused = true
	
	grabbable.focused.emit()


func unfocus(grabbable: Grabbable3D = current_grabbable):
	if grabbable and focused:
		current_grabbable = null
		focused = false
		interacting = false
		enabled = true
		
		grabbable.unfocused.emit()
