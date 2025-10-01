@tool
@icon("res://autoload/screen/reticles/reticle.svg")
class_name Reticle extends Control

@export var full_circle: bool = false:
	set(value):
		full_circle = value
		queue_redraw()
@export var radius: float = 32.0:
	set(new_radius):
		radius = new_radius
		queue_redraw()
@export var thickness: float = 1.0:
	set(new_thickness):
		thickness = new_thickness
		queue_redraw()
@export_range(0, 360.0, 0.5, "radians_as_degrees") var gap_angle: float = deg_to_rad(45.0):
	set(new_gap_angle):
		gap_angle = new_gap_angle
		queue_redraw()
@export var segments: int = 32:
	set(new_segments):
		segments = clampi(new_segments, 2, 1024)
		queue_redraw()
@export var color: Color = Color.WHITE:
	set(new_color):
		color = new_color
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if full_circle:
		draw_circle(Vector2.ZERO, radius, color)
	else:
		draw_reticle()
	

func draw_reticle() -> void:
	var arc_segments: Array[Array] = [
		[gap_angle / 2, PI / 2 - gap_angle / 2],
		[PI / 2 + gap_angle / 2, PI - gap_angle / 2],
		[PI + gap_angle / 2, 3 * PI / 2 - gap_angle / 2],
		[3 * PI / 2 + gap_angle / 2, 2 * PI - gap_angle / 2]
	]
	
	for arc: Array in arc_segments:
		var start_angle: float = arc[0]
		var end_angle: float = arc[1]
		var points: Array[Vector2] = []
		var angle_step: float = (end_angle - start_angle) / segments
		
		for i in range(segments + 1):
			var angle =  start_angle + i * angle_step
			var point = Vector2(radius * cos(angle), radius * sin(angle))
			points.append(point)
			
		if points.size():
			draw_polyline(points, color, thickness, true)


func circunference() -> void:
	gap_angle = 360.0
