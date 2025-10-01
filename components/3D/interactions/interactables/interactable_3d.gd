@icon("res://components/3D/interactions/interactables/icons/interactable_3d.svg")
class_name Interactable3D extends Area3D

const GroupName: StringName = &"interactables"

signal interacted
signal canceled_interaction
signal focused
signal unfocused
signal interaction_limit_reached


@export var activate_on_ready: bool = true
@export var number_of_times_can_be_interacted: int = 0
@export var deactivate_after_reach_interaction_limit: bool = false
@export var change_cursor_on_focus: bool = true
@export var change_reticle_on_focus: bool = true
@export var lock_player_on_interact: bool = false
@export_group("Pointers and cursors")
@export var focus_screen_pointer: CompressedTexture2D
@export var interact_screen_pointer: CompressedTexture2D
@export var focus_cursor: CompressedTexture2D
@export var interact_cursor: CompressedTexture2D


var can_be_interacted: bool = true
var times_interacted: int = 0:
	set(value):
		var previous_value = times_interacted
		times_interacted = value
		
		if previous_value != times_interacted && times_interacted >= number_of_times_can_be_interacted:
			interaction_limit_reached.emit()
			
			if deactivate_after_reach_interaction_limit:
				deactivate()
				
			can_be_interacted = false
				
			
var outline_material: StandardMaterial3D
var outline_shader_material: ShaderMaterial


func _enter_tree() -> void:
	add_to_group(GroupName)


func _ready() -> void:
	if activate_on_ready:
		activate()
	
	collision_layer = Globals.interactables_collision_layer
	collision_mask = 0
	
	interacted.connect(on_interacted)
	focused.connect(on_focused)
	unfocused.connect(on_unfocused)
	canceled_interaction.connect(on_canceled_interaction)
	
	times_interacted = 0
	
	
func activate() -> void:
	priority = 3
	collision_mask = 0
	monitorable = true
	monitoring = false
	
	can_be_interacted = true
	
	
func deactivate() -> void:
	priority = 0
	collision_layer = 0
	monitorable = false
	
	can_be_interacted = false

#region Signal callbacks
func on_interacted() -> void:
	if number_of_times_can_be_interacted > 0:
		times_interacted += 1


func on_focused() -> void:
	pass
	

func on_unfocused() -> void:
	pass


func on_scanned() -> void:
	pass


func on_canceled_interaction() -> void:
	if times_interacted < number_of_times_can_be_interacted:
		activate()
		
	pass
#endregion
