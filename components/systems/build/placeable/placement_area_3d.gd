@icon("res://components/systems/build/placeable/icons/placement_area.svg")
class_name PlacementArea3D extends Area3D

signal selected
## Where this placement area belongs
@export_flags_3d_physics var placement_layers: int = 0
## Other surfaces that can be detected
@export_flags_3d_physics var surface_masks: int = 1
@export var type: PlacementType = PlacementType.Building
@export var stackable_with: Array[PlacementType] = []
@export var raycast_position_validators: Array[RayCast3D] = []

enum PlacementType {
	Building,
	Prop,
	Defense, 
	Utility, 
	Landscape, 
	Workstation, 
	PowerGrid, 
	VehicleBay, 
	Storage, 
	Miscellaneous,
	Module,
	Trap,
	LightSource
}

var placement_is_valid: bool = false


func _ready() -> void:
	monitorable = false
	monitoring = true
	priority = 1
	collision_layer = placement_layers
	collision_mask = surface_masks


func _physics_process(_delta: float) -> void:
	placement_is_valid = is_valid()


func is_valid() -> bool:
	var other_placement_areas: Array[PlacementArea3D] 
	other_placement_areas.assign(get_overlapping_areas()\
		.filter(func(area: Area3D): 
			return area is PlacementArea3D and OmniKitArrayHelper.intersected_elements(stackable_with, area.stackable_with).is_empty()
			))
	
	return other_placement_areas.is_empty() and raycast_position_validators.all(
		func(raycast: RayCast3D): return raycast and raycast.is_colliding()
		)


func make_selectable(selectable: bool = true) -> void:
	if selectable:
		if not input_event.is_connected(on_input_event):
			input_event.connect(on_input_event, CONNECT_DEFERRED)
	
	else:
		if input_event.is_connected(on_input_event):
			input_event.disconnect(on_input_event)
		
		
func enable() -> void:
	call_deferred("set_physics_process", true)
	set_deferred("monitorable", false)
	set_deferred("monitoring", true)


func disable() -> void:
	call_deferred("set_physics_process", false)
	set_deferred("monitorable", true)
	set_deferred("monitoring", false)


func on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if OmniKitInputHelper.is_mouse_left_click(event):
		get_viewport().set_input_as_handled()
		selected.emit()
