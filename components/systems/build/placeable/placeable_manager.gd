class_name PlaceableManager extends Node

## The root node to instance the selected placeables
@export var world: Node
## The origin camera to use for placing objects when the placeable does not have one assigned
@export var origin_camera: Camera3D

## Placeable Ids
## Example: const Fridge: StringName = &"fridge"
const TestFurniture: StringName = &"test"

var placeables: Dictionary[StringName, PackedScene] = {
	TestFurniture: preload("uid://c27as6ww6qr2g")
}


var current_placeable: Placeable3D


func _ready() -> void:
	if world == null:
		world = get_tree().root
		
	assert(world is Node3D, "PlaceableManager: The world node to place objects needs to inherit from Node3D")


func spawn(id: StringName) -> void:
	if not placeables.has(id):
		push_warning("PlaceableManager: The placeable with id %s does not exists or is not assigned to a Placeable3D scene" % id)
		return
	
	if not ResourceLoader.exists(placeables[id].resource_path):
		push_warning("PlaceableManager: The placeable with id %s does not have a valid Resource to load" % id)
		return
		
	var placeable: Placeable3D = placeables[id].instantiate() as Placeable3D
	
	if placeable.origin_camera == null:
		placeable.origin_camera = origin_camera
		
	world.add_child(placeable)
	placeable.placing = true
	current_placeable = placeable
