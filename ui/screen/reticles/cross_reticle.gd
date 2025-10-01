@tool
@icon("res://ui/screen/reticles/reticle.svg")
class_name CrossReticle extends Control

@export var reticle_color: Color = Color.WHITE:
	set(value):
		if value != reticle_color:
			reticle_color = value
			
			if reticle_color:
				update_reticle_color(reticle_color)
				
## This reticle width means the distance between the two points in the line so we can adjust them using the reticle_scale value using this as base
@export var reticle_width: Vector2 = Vector2(5, 15):
	set(value):
		if value != reticle_width:
			reticle_width = value
			update_reticle_width(reticle_width)
			
@export var reticle_scale: Vector2 = Vector2.ONE:
	set(value):
		if value != reticle_scale:
			reticle_scale = value
			update_reticle_scale(reticle_scale)

@export var reticle_rotation: float = 0.0:
	set(value):
		if value != reticle_rotation:
			reticle_rotation = clampf(value, -TAU, TAU)
			update_reticle_rotation(reticle_rotation)

@export var top_reticle: Line2D ## (Vector2(0, -5), Vector2(0, -15)
@export var bottom_reticle: Line2D ## (Vector2(0, 5), Vector2(0, 15)
@export var right_reticle: Line2D ## (Vector2(5, 0), Vector2(15, 0)
@export var left_reticle: Line2D ## (Vector2(-5, 0), Vector2(-15, 0)

var top_reticle_original_position: Vector2
var bottom_reticle_original_position: Vector2
var right_reticle_original_position: Vector2
var left_reticle_original_position: Vector2

var top_reticle_original_rotation: float
var bottom_reticle_original_rotation: float
var right_reticle_original_rotation: float
var left_reticle_original_rotation: float

var current_width: Vector2
var current_color: Color


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	top_reticle_original_position = top_reticle.position
	bottom_reticle_original_position = bottom_reticle.position
	right_reticle_original_position = right_reticle.position
	left_reticle_original_position = left_reticle.position
	
	update_reticle_width()
	update_reticle_color()


func display_cross_reticle() -> CrossReticle:
	top_reticle.show()
	bottom_reticle.show()
	right_reticle.show()
	left_reticle.show()
	
	return self


func display_top_reticle() -> CrossReticle:
	top_reticle.display()
	
	return self

func display_bottom_reticle() -> CrossReticle:
	bottom_reticle.show()
	
	return self
	
	
func display_right_reticle() -> CrossReticle:
	right_reticle.show()
	
	return self


func display_left_reticle() -> CrossReticle:
	left_reticle.show()
	
	return self
	
	
func hide_top_reticle() -> CrossReticle:
	top_reticle.hide()
	
	return self

func hide_bottom_reticle() -> CrossReticle:
	bottom_reticle.hide()
	
	return self
	
	
func hide_right_reticle() -> CrossReticle:
	right_reticle.hide()
	
	return self


func hide_left_reticle() -> CrossReticle:
	left_reticle.hide()
	
	return self


func hide_cross_reticle() -> CrossReticle:
	top_reticle.hide()
	bottom_reticle.hide()
	right_reticle.hide()
	left_reticle.hide()
	
	return self


func update_reticle_width(new_width: Vector2 = reticle_width) -> CrossReticle:
	top_reticle.clear_points()
	bottom_reticle.clear_points()
	right_reticle.clear_points()
	left_reticle.clear_points()
	
	top_reticle.add_point(Vector2(0, -new_width.x))
	top_reticle.add_point(Vector2(0, -new_width.y ))
	
	bottom_reticle.add_point(Vector2(0, new_width.x))
	bottom_reticle.add_point(Vector2(0, new_width.y))
	
	right_reticle.add_point(Vector2(new_width.x, 0))
	right_reticle.add_point(Vector2(new_width.y, 0))
	
	left_reticle.add_point(Vector2(-new_width.x, 0))
	left_reticle.add_point(Vector2(-new_width.y, 0))
	
	return self


func update_reticle_scale(new_scale: Vector2 = reticle_scale) -> CrossReticle:
	top_reticle.scale = new_scale
	bottom_reticle.scale = new_scale
	right_reticle.scale = new_scale
	left_reticle.scale = new_scale
	
	return self


func update_reticle_color(new_color: Color = reticle_color) -> CrossReticle:
	top_reticle.default_color = new_color
	bottom_reticle.default_color = new_color
	right_reticle.default_color = new_color
	left_reticle.default_color = new_color
	
	return self


func update_reticle_rotation(new_rotation: float = reticle_rotation) -> CrossReticle:
	new_rotation = clampf(new_rotation, -TAU, TAU)
	
	top_reticle.rotation = new_rotation
	bottom_reticle.rotation = new_rotation
	right_reticle.rotation = new_rotation
	left_reticle.rotation = new_rotation
	
	return self


func reset_reticles_position_to_default() -> CrossReticle:
	top_reticle.position = top_reticle_original_position
	bottom_reticle.position = bottom_reticle_original_position
	right_reticle.position = right_reticle_original_position
	left_reticle.position = left_reticle_original_position
	
	return self


func reset_all_values_to_default() -> CrossReticle:
	reset_reticles_position_to_default()
	update_reticle_rotation(reticle_rotation)
	update_reticle_color(reticle_color)
	
	return self


#region Animations
func expand_reticles_smooth(distance: float = 5.0, time: float = 0.15) -> void:
		var tween: Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		tween.tween_property(top_reticle, "position", top_reticle.position + Vector2.UP.rotated(top_reticle.rotation) * distance, time)
		tween.tween_property(bottom_reticle, "position", bottom_reticle.position + Vector2.DOWN.rotated(bottom_reticle.rotation) * distance, time)
		tween.tween_property(right_reticle, "position", right_reticle.position + Vector2.RIGHT.rotated(right_reticle.rotation) * distance, time)
		tween.tween_property(left_reticle, "position", left_reticle.position + Vector2.LEFT.rotated(left_reticle.rotation) * distance, time)
		
		await tween.finished


func rotate_reticles_smooth(angle_in_degrees: float = 45, time: float = 0.15) -> void:
	var tween: Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(top_reticle, "rotation", top_reticle.rotation + deg_to_rad(angle_in_degrees), time)
	tween.tween_property(bottom_reticle, "rotation", bottom_reticle.rotation + deg_to_rad(angle_in_degrees), time)
	tween.tween_property(right_reticle, "rotation", right_reticle.rotation + deg_to_rad(angle_in_degrees), time)
	tween.tween_property(left_reticle, "rotation", left_reticle.rotation + deg_to_rad(angle_in_degrees), time)

	await tween.finished
	
	
func reset_reticles_position_to_default_smooth(time: float = 0.15) -> void:
	var tween: Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(top_reticle, "position", top_reticle_original_position, time)
	tween.tween_property(bottom_reticle, "position", bottom_reticle_original_position, time)
	tween.tween_property(right_reticle, "position", right_reticle_original_position, time)
	tween.tween_property(left_reticle, "position", left_reticle_original_position, time)

	
func reset_reticles_rotation_to_default_smooth(time: float = 0.15) -> void:
	var tween: Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(top_reticle, "rotation", top_reticle_original_rotation, time)
	tween.tween_property(bottom_reticle, "rotation", bottom_reticle_original_rotation, time)
	tween.tween_property(right_reticle, "rotation", right_reticle_original_rotation, time)
	tween.tween_property(left_reticle, "rotation", left_reticle_original_rotation, time)

#endregion
