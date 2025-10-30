class_name OmniKitDraggable2D extends Button

signal dragged
signal released
signal locked
signal unlocked

@export var draggable: Node
@export var drag_smooth_lerp_factor: float = 20.0
@export var character_body_speed: float = 1000.0
@export var screen_limit: bool = true


var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()
			
			if draggable is CharacterBody2D:
				set_physics_process(is_dragging and not is_locked)
			else:
				set_process(is_dragging and not is_locked)
			
var is_dragging: bool = false:
	set(value):
		if value != is_dragging:
			is_dragging = value
			
			if is_dragging:
				dragged.emit()
			else:
				released.emit()
			
			if draggable is CharacterBody2D:
				set_physics_process(is_dragging and not is_locked)
			else:
				set_process(is_dragging and not is_locked)

var original_z_index: int = 0
var original_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0
var current_position: Vector2 = Vector2.ZERO

var last_mouse_position: Vector2
var velocity: Vector2

var draggable_group_nodes: Array[Node2D] = []
var draggable_group_offsets: Array[Vector2] = []
var group_origin_global: Vector2 = Vector2.ZERO
var prev_group_origin_global: Vector2 = Vector2.ZERO


func set_draggable_linked_group(group_nodes: Array) -> void:
	if draggable:
		draggable_group_nodes.clear()
		draggable_group_offsets.clear()
		
		group_origin_global = draggable.global_position
		prev_group_origin_global = group_origin_global
		draggable_group_nodes.assign(group_nodes.filter(func(node: Node): return is_instance_valid(node) and node is Node2D))
		
		for group_node: Node2D in draggable_group_nodes:
			draggable_group_offsets.append(group_node.global_position - group_origin_global)


func _ready() -> void:
	if draggable == null:
		draggable = get_parent()
		
	assert(is_instance_valid(draggable) and (draggable is Node2D or draggable is Control), "OmniKitDraggable2D: This mouse drag region needs a valid Node2D or Control to works properly")
	
	set_process(false)
	set_physics_process(false)
	#position = Vector2.ZERO
	self_modulate.a8 = 0
	
	original_position = draggable.global_position
	original_rotation = draggable.rotation
	original_z_index = draggable.z_index
	
	button_down.connect(on_mouse_drag_region_dragged)
	button_up.connect(on_mouse_drag_region_released)
	anchors_preset = Control.PRESET_FULL_RECT
	

func _process(delta: float) -> void:
	if not is_locked and is_dragging:
		if drag_smooth_lerp_factor > 0:
			draggable.global_position = draggable.global_position.lerp(get_global_mouse_position(), drag_smooth_lerp_factor * delta)
		else:
			draggable.global_position = get_global_mouse_position()
			
		current_position = draggable.global_position
		
		apply_screen_limit()
		apply_group_movement(current_position)


func _physics_process(delta: float) -> void:
	if not is_locked and is_dragging:
		var mouse_position: Vector2 = get_global_mouse_position()
		
		if draggable.global_position.distance_to(mouse_position) < 2.0:
			draggable.velocity = Vector2.ZERO
		else:
			if drag_smooth_lerp_factor > 0:
				draggable.velocity = lerp(
						draggable.velocity, 
						draggable.global_position.direction_to(mouse_position) * character_body_speed, 
						drag_smooth_lerp_factor * delta
					)
			else:
				draggable.velocity = draggable.global_position.direction_to(mouse_position) * character_body_speed
			
		draggable.move_and_slide()
		
		current_position = draggable.global_position
		apply_screen_limit()
		apply_group_movement(current_position)
	

func apply_group_movement(new_position: Vector2) -> void:
	for group_index: int in range(draggable_group_nodes.size()):
		var group_node: Node2D = draggable_group_nodes[group_index]
		group_node.global_position = new_position + draggable_group_offsets[group_index]

	prev_group_origin_global = group_origin_global
	group_origin_global = new_position


func apply_screen_limit() -> void:
	if screen_limit:
		draggable.global_position = Vector2(
			clampf(draggable.global_position.x, 0 , get_viewport_rect().size.x), 
			clampf(draggable.global_position.y, 0 , get_viewport_rect().size.y)
		)


func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


func start_drag() -> void:
	if not is_locked:
		is_dragging = true
		draggable.z_index = original_z_index + 100
		draggable.z_as_relative = false
		
		for draggable_group_node: Node2D in draggable_group_nodes:
			draggable_group_node.z_index = original_z_index + 100
			draggable_group_node.z_as_relative = false


func release_drag() -> void:
	if not is_locked:
		is_dragging = false
		draggable.z_index = original_z_index
		draggable.z_as_relative = true
		
		for draggable_group_node: Node2D in draggable_group_nodes:
			draggable_group_node.z_index = original_z_index
			draggable_group_node.z_as_relative = true
			
		draggable_group_nodes.clear()
		draggable_group_offsets.clear()
#endregion

#region Signal callbacks
func on_mouse_drag_region_dragged() -> void:
	start_drag()


func on_mouse_drag_region_released() -> void:
	release_drag()
#endregion
