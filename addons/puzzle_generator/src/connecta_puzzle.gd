class_name ConnectaPuzzle extends Node2D

signal puzzle_generated
signal puzzle_finished


const MasksPath: StringName = &"res://addons/puzzle_generator/src/shader/masks/"
const PuzzlePieceScene: PackedScene = preload("uid://cy53228ilv3wo")
const PuzzleMaskShaderMaterial: ShaderMaterial = preload("uid://eb4n3d3w5in")

enum PieceStyle {Straight, Inset, Outset}
enum PieceSide {Top, Right, Bottom, Left}
enum GenerationType {
	Automatic, ## Generates automatically the puzzle when this node is ready and a puzzle texture is assigned
	Manual ## For better control, when this mode is set, you need to call the function generate_puzzle() manually to generate a puzzle.
	}

@export var output_node: Node2D
@export var draggable_component: OmniKitDraggable2D
@export var generation_type: GenerationType = GenerationType.Automatic
@export var puzzle_texture: Texture2D:
	set(value):
		puzzle_texture = value
		current_puzzle_image = puzzle_texture.get_image() if puzzle_texture else null
		
@export_range(4, 10000, 1) var number_of_pieces: int = 100
@export var piece_margin: float = 0.15

var cached_masks: Dictionary = {}
var current_pieces: Array[PuzzlePiece] = []
var current_puzzle_image: Image:
	set(new_image):
		current_puzzle_image = new_image
		
		if current_puzzle_image:
			_prepare_image(current_puzzle_image)
			

func _ready() -> void:
	assert(draggable_component != null, "ConnectaPuzzle: This node needs a Draggable2D in order to drag drop the pieces.")
	
	if output_node == null:
		output_node = self
		
	_prepare_masks()
	
	if puzzle_texture:
		current_puzzle_image = puzzle_texture.get_image()
		
		if generation_type == GenerationType.Automatic:
			generate_puzzle(current_puzzle_image)
		

func generate_puzzle(puzzle_image: Image = current_puzzle_image) -> void:
	assert(cached_masks.size() > 0, "ConnectaPuzzle->generate_puzzle: There is no available puzzle image masks to generate the puzzle, aborting... ")
	
	var piece_size: int = _calculate_piece_size(current_puzzle_image)
	var margin: float = piece_size * piece_margin
	var horizontal_pieces: int = floori(puzzle_image.get_width() / piece_size)
	var vertical_pieces: int = floori(puzzle_image.get_height() / piece_size)
	
	print_rich("[b]ConnectaPuzzle:[/b] [color=green]Generating a new puzzle of %d pieces with an image of %s gives a total[/color] [color=yellow][i]%dx%d = %d pieces.[/i][/color] [color=white][i]The number of final pieces could be less to fit the correct image size.[/i][/color]" % [number_of_pieces, str(current_puzzle_image.get_size()), horizontal_pieces, vertical_pieces, horizontal_pieces * vertical_pieces])
	
	current_pieces.clear()
	draggable_component.set_deferred("size", Vector2.ZERO)
	
	for vertical_piece: int in vertical_pieces:
		for horizontal_piece: int in horizontal_pieces:
			var puzzle_piece: PuzzlePiece = PuzzlePieceScene.instantiate() as PuzzlePiece
			puzzle_piece.name = "PuzzlePiece_%d_%d" % [horizontal_piece, vertical_piece]
			puzzle_piece.row = horizontal_piece
			puzzle_piece.col = vertical_piece
			puzzle_piece.piece_size = piece_size
			puzzle_piece.region_enabled = true
			puzzle_piece.region_rect = _calculate_piece_rect(horizontal_piece, vertical_piece, piece_size, margin)
			puzzle_piece.sides = _generate_piece_sides(current_pieces, horizontal_piece, vertical_piece, horizontal_pieces, vertical_pieces)
			puzzle_piece.mask = cached_masks[puzzle_piece.sides[PieceSide.Top]][puzzle_piece.sides[PieceSide.Right]][puzzle_piece.sides[PieceSide.Bottom]][puzzle_piece.sides[PieceSide.Left]]
			puzzle_piece.mask_shader_material = PuzzleMaskShaderMaterial
			puzzle_piece.texture = puzzle_texture
			add_neighbours_to_piece(current_pieces, puzzle_piece, horizontal_piece, vertical_piece, horizontal_pieces)
			current_pieces.append(puzzle_piece)
	
	## The pieces are added after the preparing loop
	## as the neighbours are setup correctly now to delete the proper detection areas
	## when puzzle piece trigger _ready()
	for piece: PuzzlePiece in current_pieces:
		output_node.add_child(piece)
		piece.position.x = piece.row * piece_size
		piece.position.y = piece.col * piece_size

		piece.dragged.connect(on_piece_dragged.bind(piece))
		piece.released.connect(on_piece_released.bind(piece))
	

	#fit_camera_to_puzzle(get_viewport().get_camera_2d(), puzzle_image.get_width(), puzzle_image.get_height(), get_viewport_rect().size)
	
	puzzle_generated.emit()


func fit_camera_to_puzzle(camera: Camera2D, puzzle_width: int, puzzle_height: int, viewport_size: Vector2) -> void:
	if not camera:
		return
	
	var zoom_x: float = puzzle_width / viewport_size.x
	var zoom_y: float = puzzle_height / viewport_size.y

	var target_zoom: float = max(zoom_x, zoom_y)
	
	camera.zoom = Vector2(target_zoom, target_zoom) * 0.9
	
	var puzzle_center = Vector2(puzzle_width, puzzle_height) * 0.5
	camera.position = puzzle_center
	
	
func is_puzzle_finished() -> bool:
	return current_pieces.size() == current_pieces.filter(func(piece: PuzzlePiece): return piece.active_areas.size() == 0).size()


#region Piece related
func pieces_from_group(group: String) -> Array[PuzzlePiece]:
	var pieces: Array[PuzzlePiece] = []
	pieces.assign(output_node.get_tree()\
		.get_nodes_in_group(group)\
		.filter(func(child: Node): return is_instance_valid(child) and child is PuzzlePiece))
	
	return pieces


func detect_pieces_connections(source_piece: PuzzlePiece, reposition: bool = true) -> void:
	for current_side_area: Area2D in source_piece.active_areas.filter(func(area: Area2D): return not area.is_queued_for_deletion()):
		var side: String = current_side_area.get_meta(&"side")
		
		if side == null or side.is_empty() or not source_piece.opposite_neighbours.has(side):
			continue
			
		var opposite: Dictionary = source_piece.opposite_neighbours[side]
		var detected_piece_areas = current_side_area.get_overlapping_areas()\
					.filter(func(area: Area2D): return area.get_meta(&"side") == opposite["opposite_side"])
		
		for piece_area: Area2D in detected_piece_areas:
			var detected_piece: PuzzlePiece = piece_area.get_parent() as PuzzlePiece

			if opposite["neighbor"] != null \
				and opposite["neighbor"] == detected_piece \
				and piece_area.global_position.distance_to(current_side_area.global_position) < (source_piece.piece_size * 0.75):
				
				source_piece.remove_side_area(current_side_area)
				detected_piece.remove_side_area(piece_area)
				
				var current_group_pieces: Array[PuzzlePiece] = pieces_from_group(source_piece.group_id)
				var detected_piece_group_pieces: Array[PuzzlePiece] = pieces_from_group(detected_piece.group_id)
				
				var smaller_group: Array[PuzzlePiece] = []
				var master_piece: PuzzlePiece ## This one is used as reference position to adjust the slave piece
				var slave_piece: PuzzlePiece

				if current_group_pieces.size() > detected_piece_group_pieces.size():
					smaller_group = detected_piece_group_pieces
					master_piece = source_piece
					slave_piece = detected_piece
				else:
					smaller_group = current_group_pieces
					master_piece = detected_piece
					slave_piece = source_piece
				
				var reference_position: Vector2 = master_piece.global_position
				var side_direction: int = -1.0 if master_piece == detected_piece else 1.0
				
				match side:
					"top":
						reference_position.y -= master_piece.piece_size * side_direction
					"bottom":
						reference_position.y += master_piece.piece_size * side_direction
					"left":
						reference_position.x -= master_piece.piece_size * side_direction
					"right":
						reference_position.x += master_piece.piece_size * side_direction
				
				var group_adjust_offset: Vector2 = reference_position - slave_piece.global_position

				for smaller_group_piece: PuzzlePiece in smaller_group:
					smaller_group_piece.group_id = master_piece.group_id
					smaller_group_piece.global_position += group_adjust_offset


func _calculate_piece_size(puzzle_image: Image) -> int:
	var image_size: Vector2i = puzzle_image.get_size()
	var y: float = sqrt( ((image_size.y * number_of_pieces ) / image_size.x) )

	return floori(image_size.y / y)
	
	
func _calculate_piece_size_by_aspect_ratio(puzzle_image: Image) -> Vector2i:
	var image_size: Vector2i = puzzle_image.get_size()
	var pieces_per_row: int = ceili(sqrt(number_of_pieces * (image_size.x / image_size.y)))
	var pieces_per_col: int = ceili(number_of_pieces / pieces_per_row)
	
	var piece_width: int = floori(image_size.x / pieces_per_row)
	var piece_height: int = floori(image_size.y / pieces_per_col)
	
	piece_width = piece_width * (1.0 - piece_margin)
	piece_height = piece_height * (1.0 - piece_margin)
	
	return Vector2i(piece_width, piece_height)


func _calculate_piece_rect(horizontal_piece: int, vertical_piece: int, size: int, margin: float) -> Rect2:
	return Rect2(horizontal_piece * size - margin, vertical_piece * size - margin, size + ( 2 * margin), size + ( 2 * margin))


func opposing_piece_set(piece: PuzzlePiece, side: PieceSide) -> PieceStyle:
	return PieceStyle.Outset if piece.sides[side] == PieceStyle.Inset else PieceStyle.Inset

	
func _generate_piece_sides(pieces_stack: Array[PuzzlePiece], horizontal_piece: int, vertical_piece: int, num_horizontal_pieces: int, num_vertical_pieces: int) -> Dictionary:
	var rv: Dictionary = {}
	
	if horizontal_piece == num_horizontal_pieces - 1:
		rv[PieceSide.Right] = PieceStyle.Straight
	else:
		if randf() > 0.5:
			rv[PieceSide.Right] = PieceStyle.Inset
		else:
			rv[PieceSide.Right] = PieceStyle.Outset
			
	if vertical_piece == num_vertical_pieces - 1:
		rv[PieceSide.Bottom] = PieceStyle.Straight
	else:
		if randf() > 0.5:
			rv[PieceSide.Bottom] = PieceStyle.Inset
		else:
			rv[PieceSide.Bottom] = PieceStyle.Outset
	
	if horizontal_piece > 0:
		rv[PieceSide.Left] = opposing_piece_set(pieces_stack.back(), PieceSide.Right)
	else:
		rv[PieceSide.Left] = PieceStyle.Straight
		
	if vertical_piece > 0:
		rv[PieceSide.Top] = opposing_piece_set(pieces_stack[pieces_stack.size() - num_horizontal_pieces], PieceSide.Bottom)
	else:
		rv[PieceSide.Top] = PieceStyle.Straight
		
	return rv

func add_neighbours_to_piece(pieces_stack: Array[PuzzlePiece], piece: PuzzlePiece, horizontal: int, vertical: int, horizontal_pieces:int) -> void:
	if horizontal > 0:
		var left_piece: PuzzlePiece = pieces_stack.back()
		left_piece.right_neighbor = piece
		piece.left_neighbor = left_piece
		
	if vertical > 0:
		var top_piece: PuzzlePiece = pieces_stack[pieces_stack.size() - horizontal_pieces]
		top_piece.bottom_neighbor = piece
		piece.top_neighbor = top_piece

#endregion

#region Preparation helpers
func _prepare_image(selected_image: Image = current_puzzle_image) -> ConnectaPuzzle:
	selected_image.convert(Image.FORMAT_RGB8)
	selected_image.fix_alpha_edges()
	
	return self


func _prepare_masks(masks_path: StringName = MasksPath) -> ConnectaPuzzle:
	if cached_masks.is_empty():
		## Side values
		for tops in PieceStyle.values():
			cached_masks[tops] = {}
			for rights in PieceStyle.values():
				cached_masks[tops][rights] = {}
				for bottoms in PieceStyle.values():
					cached_masks[tops][rights][bottoms] = {}
					for lefts in PieceStyle.values():
						cached_masks[tops][rights][bottoms][lefts] = null
		
		## Load mask image and assign it to sides
		for top_style in PieceStyle.values():
			for right_style in PieceStyle.values():
				for bottom_style in PieceStyle.values():
					for left_style in PieceStyle.values():
						var sides: Dictionary = {
							PieceSide.Top: top_style,
							PieceSide.Right: right_style,
							PieceSide.Bottom: bottom_style,
							PieceSide.Left: left_style
						}
						
						var mask_image_path: String = masks_path + str(top_style) + "_" + str(right_style) + "_" + str(bottom_style) + "_" + str(left_style) + ".png"
						
						if ResourceLoader.exists(mask_image_path):
							cached_masks[top_style][right_style][bottom_style][left_style] = load(mask_image_path)
	return self
	
#endregion

func on_piece_dragged(piece: PuzzlePiece) -> void:
	if not draggable_component.is_dragging:
		var group_pieces: Array[PuzzlePiece] = pieces_from_group(piece.group_id)
		draggable_component.draggable = piece
		draggable_component.set_draggable_linked_group(group_pieces)
		draggable_component.start_drag()
		
		for active_piece: PuzzlePiece in group_pieces:
			active_piece.call_deferred("border_areas_detection_mode")


func on_piece_released(piece: PuzzlePiece) -> void:
	draggable_component.release_drag()
	draggable_component.draggable = null
	detect_pieces_connections(piece)
	
	for puzzle_piece: PuzzlePiece in current_pieces:
		for area: Area2D in puzzle_piece.active_areas.filter(func(area: Area2D): return not area.is_queued_for_deletion()):
			puzzle_piece.call_deferred("border_areas_detected_mode")
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if is_puzzle_finished():
		puzzle_finished.emit()
