@icon("res://components/systems/build/placeable/icons/placement_area.svg")
class_name PlacementArea3D extends Area3D

signal place_valid
signal place_invalid

## Where this placement area belongs
@export_flags_3d_physics var placement_layers: int = 0
## Other surfaces that can be detected
@export_flags_3d_physics var surface_masks: int = 1
@export var type: PlacementType = PlacementType.Building
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

func _ready() -> void:
	monitorable = true
	monitoring = true
	priority = 1
	collision_layer = placement_layers
	collision_mask = surface_masks




func enable() -> void:
	show()


func disable() -> void:
	hide()
