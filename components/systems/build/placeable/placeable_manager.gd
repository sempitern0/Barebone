class_name PlaceableManager extends Node

## The root node to instance the selected placeables
@export var world: Node

## Placeable Ids
## Example: const Fridge: StringName = &"fridge"

const TestFurniture: StringName = &"test"


var placeables: Dictionary[StringName, PackedScene] = {
	TestFurniture: preload("uid://c27as6ww6qr2g")
}


func _ready() -> void:
	if world == null:
		world = get_tree().root


func spawn(id: StringName) -> void:
	if placeables.has(id):
		var placeable: Placeable3D = placeables[id].instantiate() as Placeable3D
		
		world.add_child(placeable)
