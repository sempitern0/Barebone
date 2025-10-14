class_name PlaceableManager extends Node

signal placement_rejected(placeable: Placeable3D, reason: String)

## The root node to instance the selected placeables
@export var world: Node
@export var placer: Placer3D
@onready var aerial_camera: AerialCamera = $"../AerialCamera"


#region Placeable IDs
## Example: const Fridge: StringName = &"fridge"
#endregion

var available_placeables: Dictionary[StringName, PackedScene] = {
	&"cubo": preload("uid://bf40rr33g3eat")
}

var world_placeables: Dictionary[StringName, Array] = {} ## Array[Placeable3D]


func _ready() -> void:
	if world == null:
		world = get_tree().root
		
	assert(world != null and world is Node3D, "PlaceableManager: The world node to place objects needs to inherit from Node3D.")
	assert(placer != null and placer is Placer3D, "PlaceableManager: This manager needs a Placer3D.")
	
	placer.placed.connect(on_placed_placeable)


func spawn(id: StringName) -> void:
	if not available_placeables.has(id):
		push_error("PlaceableManager: The placeable with id %s does not exists or is not assigned to a Placeable3D scene" % id)
		return
	
	if not ResourceLoader.exists(available_placeables[id].resource_path):
		push_error("PlaceableManager: The placeable with id %s does not have a valid Resource to load" % id)
		return
	
	var placeable: Placeable3D = _scene_is_valid_placeable(available_placeables[id].instantiate())
		
	if placeable == null:
		push_error("PlaceableManager: The scene with id %s is not valid, needs to be a Placeable3D or have it as a child." % id)
		return
	
	if placeable.limit_in_the_world > 0 and world_placeables.has(id) and world_placeables[id].size() > placeable.limit_in_the_world:
		placement_rejected.emit(placeable, "PLACEABLE_WORLD_LIMIT_ERROR")
		return
	
	placer.cancel_placement()
	world.add_child(placeable.target)
	placeable.target.position = placer.world_projected_position().position
	placer.call_deferred("start_placement", placeable)
	
	
func add_to_world_placeables(placeable: Placeable3D) -> void:
	if world_placeables.has(placeable.id):
		world_placeables[placeable.id].append(placeable)
	else:
		world_placeables[placeable.id] = [placeable]

## The Placeable3D could be a component on the scene instead of the root node.
func _scene_is_valid_placeable(placeable_scene: Node3D) -> Placeable3D:
	if placeable_scene is Placeable3D:
		return placeable_scene

	for child: Node in OmniKitNodeTraversal.get_all_children(placeable_scene):
		if child is Placeable3D:
			return child
		
	return null


func on_placed_placeable(placeable: Placeable3D, repositioned: bool) -> void:
	if not repositioned:
		add_to_world_placeables(placeable)
		
		if placeable.can_be_repositioned and not placeable.placement_requested.is_connected(on_replacement_requested.bind(placeable)):
			placeable.placement_requested.connect(on_replacement_requested.bind(placeable))

func on_replacement_requested(placeable: Placeable3D) -> void:
	placer.start_placement(placeable)
