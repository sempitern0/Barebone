class_name ConnectaPuzzle extends Node2D

signal puzzle_generated
signal puzzle_finished


const MasksPath: StringName = &"res://addons/puzzle_generator/src/shader/masks/"
const PuzzlePieceScene: PackedScene = preload("uid://cy53228ilv3wo")
const PuzzleMosaicAreaScene: PackedScene = preload("uid://cckweb73gxxrb")
const PuzzleMaskShaderMaterial: ShaderMaterial = preload("uid://eb4n3d3w5in")

enum PieceStyle {Straight, Inset, Outset}
enum PieceSide {Top, Right, Bottom, Left}
enum GenerationType {
	Automatic, ## Generates automatically the puzzle when this node is ready and a puzzle texture is assigned
	Manual ## For better control, when this mode is set, you need to call the function generate_puzzle() manually to generate a puzzle.
	}

enum PuzzleMode {
	Free, ## Connect the pieces freely between them
	Mosaic ## Drag the piece in the correct mosaic position where the piece belongs using the puzzle image as background transparency.
}

enum ShuffleMode {
	AroundTheViewport,
	Center,
	Bottom
}

enum SpawnDistributionMode {
	Random,
	Equidistant,
	Radial
}

@export var output_node: Node2D
@export var draggable_component: OmniKitDraggable2D
@export var generation_type: GenerationType = GenerationType.Automatic
@export var puzzle_mode: PuzzleMode = PuzzleMode.Free
@export var shuffle_mode: ShuffleMode = ShuffleMode.AroundTheViewport
@export var spawn_distribution_mode: SpawnDistributionMode = SpawnDistributionMode.Random
@export var puzzle_texture: Texture2D:
	set(value):
		puzzle_texture = value
		current_puzzle_image = puzzle_texture.get_image() if puzzle_texture else null

@export_range(0.0, 255.0, 0.1) var background_mosaic_transparency: float = 100.0
@export_range(4, 10000, 1) var number_of_pieces: int = 100
@export var piece_margin: float = 0.15
## How much the piece is separated from the puzzle background when spawning
@export var spawn_margin: float = 50.0

var cached_masks: Dictionary = {}
var current_pieces: Array[PuzzlePiece] = []
var current_puzzle_image: Image:
	set(new_image):
		current_puzzle_image = new_image
		
		if current_puzzle_image:
			_prepare_image(current_puzzle_image)

## Used when Mosaic mode to display the puzzle as transparent background
var background_puzzle: Sprite2D

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
	
	var piece_size: Vector2i = _calculate_piece_size(current_puzzle_image)
	
	if not is_equal_approx(current_puzzle_image.get_width(), current_puzzle_image.get_height()):
		piece_size = _calculate_piece_size_by_aspect_ratio(current_puzzle_image)
		
	var margin: Vector2 =  Vector2(piece_size.x, piece_size.y) * piece_margin
	var horizontal_pieces: int = floori(puzzle_image.get_width() / piece_size.x)
	var vertical_pieces: int = floori(puzzle_image.get_height() / piece_size.y)
	
	print_rich("[b]ConnectaPuzzle:[/b] [color=green]Generating a new puzzle of %d pieces with an image of %s gives a total[/color] [color=yellow][i]%dx%d = %d pieces.[/i][/color] [color=white][i]The number of final pieces could be less to fit the correct image size.[/i][/color]" % [number_of_pieces, str(current_puzzle_image.get_size()), horizontal_pieces, vertical_pieces, horizontal_pieces * vertical_pieces])
	
	current_pieces.clear()
	draggable_component.set_deferred("size", Vector2.ZERO)
	
	for vertical_piece: int in vertical_pieces:
		for horizontal_piece: int in horizontal_pieces:
			var puzzle_piece: PuzzlePiece = PuzzlePieceScene.instantiate() as PuzzlePiece
			puzzle_piece.name = "PuzzlePiece_%d_%d" % [horizontal_piece, vertical_piece]
			puzzle_piece.puzzle_mode = puzzle_mode
			puzzle_piece.row = vertical_piece
			puzzle_piece.col = horizontal_piece
			puzzle_piece.piece_size = piece_size
			puzzle_piece.region_enabled = true
			puzzle_piece.region_rect = _calculate_piece_rect(horizontal_piece, vertical_piece, piece_size, margin)
			puzzle_piece.sides = _generate_piece_sides(current_pieces, horizontal_piece, vertical_piece, horizontal_pieces, vertical_pieces)
			puzzle_piece.mask = cached_masks[puzzle_piece.sides[PieceSide.Top]][puzzle_piece.sides[PieceSide.Right]][puzzle_piece.sides[PieceSide.Bottom]][puzzle_piece.sides[PieceSide.Left]]
			puzzle_piece.mask_shader_material = PuzzleMaskShaderMaterial
			puzzle_piece.texture = puzzle_texture
			add_neighbours_to_piece(current_pieces, puzzle_piece, horizontal_piece, vertical_piece, horizontal_pieces)
			current_pieces.append(puzzle_piece)
	
	## Always add the background puzzle as it used as reference
	## to position the pieces for the shuffle mode
	var background_puzzle_final_half_size: Vector2 = _prepare_background_puzzle_transparent_texture(piece_size, horizontal_pieces, vertical_pieces)
	background_puzzle.hide()
	
	if puzzle_mode == PuzzleMode.Mosaic:
		background_puzzle.show()
	## The pieces are added after the preparing loop
	## as the neighbours are setup correctly now to delete the proper detection areas
	## when puzzle piece trigger _ready()
	for piece: PuzzlePiece in current_pieces:
		output_node.add_child(piece)
		
		## Uncomment to position the pieces to see the finished puzzle
		#piece.position.x = piece.col * piece_size.x
		#piece.position.y = piece.row * piece_size.y
		if puzzle_mode == PuzzleMode.Mosaic:
			var mosaic_area: PuzzleMosaicArea = PuzzleMosaicAreaScene.instantiate() as PuzzleMosaicArea
			background_puzzle.add_child(mosaic_area)
			mosaic_area.puzzle_piece = piece
			
			mosaic_area.position.x = (piece.col * piece_size.x) + piece_size.x / 2.0
			mosaic_area.position.y = (piece.row  * piece_size.y) + piece_size.y / 2.0
			
			if background_puzzle.centered:
				mosaic_area.position.x -= background_puzzle_final_half_size.x
				mosaic_area.position.y -= background_puzzle_final_half_size.y
				
			piece.mosaic_layer = mosaic_area.mosaic_layer
	
		match shuffle_mode:
			ShuffleMode.AroundTheViewport:
				piece.position = generate_spawn_puzzle_position(background_puzzle, piece.piece_size, 200.0, spawn_margin, spawn_distribution_mode)

		piece.dragged.connect(on_piece_dragged.bind(piece))
		piece.released.connect(on_piece_released.bind(piece))

	#fit_camera_to_puzzle(get_viewport().get_camera_2d(), puzzle_image.get_width(), puzzle_image.get_height(), get_viewport_rect().size)
	
	puzzle_generated.emit()


func generate_spawn_puzzle_position(puzzle: Sprite2D,  piece_size: Vector2, spawn_area_size: float = 500.0,  margin: float = spawn_margin, spawn_mode: SpawnDistributionMode = spawn_distribution_mode) -> Vector2:
	var puzzle_size: Vector2 = puzzle.texture.get_size() * puzzle.scale
	var puzzle_half_size: Vector2 = puzzle_size / 2.0
	var puzzle_center: Vector2 = puzzle.position
	
	match spawn_mode:
		SpawnDistributionMode.Random:
			var top_spawn_reference: float = Vector2.UP.y * (puzzle.position.y + puzzle_half_size.y + piece_size.y / 2.0 + margin)
			var bottom_spawn_reference: float = Vector2.DOWN.y * (puzzle.position.y + puzzle_half_size.y + piece_size.y / 2.0 + margin)
			var right_spawn_reference: float = Vector2.RIGHT.x * (puzzle.position.x + puzzle_half_size.x + piece_size.x / 2.0 + margin)
			var left_spawn_reference: float = Vector2.LEFT.x * (puzzle.position.x + puzzle_half_size.x + piece_size.x / 2.0 + margin)
			
			match OmniKitVectorHelper.directions_v2.pick_random():
				Vector2.UP:
					return Vector2(randf_range(-puzzle_half_size.x, puzzle_half_size.x), top_spawn_reference - randf_range(0, spawn_area_size))
				Vector2.DOWN:
					return Vector2(randf_range(-puzzle_half_size.x, puzzle_half_size.x), bottom_spawn_reference + randf_range(0, spawn_area_size))
				Vector2.LEFT:
					return Vector2(left_spawn_reference - randf_range(0, spawn_area_size), randf_range(-puzzle_half_size.y, puzzle_half_size.y))
				Vector2.RIGHT:
					return Vector2(right_spawn_reference + randf_range(0, spawn_area_size), randf_range(-puzzle_half_size.y, puzzle_half_size.y))
		
		SpawnDistributionMode.Radial:
			var min_radius: float = maxf(puzzle_half_size.x, puzzle_half_size.y) + piece_size.length() + margin
			var radius: float = randf_range(min_radius, min_radius + spawn_area_size)
			var angle: float = randf_range(0.0, TAU)
			
			return puzzle_center + Vector2(cos(angle), sin(angle)) * radius
			
	return Vector2.ZERO
	
	
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
	match puzzle_mode:
		PuzzleMode.Free:
			return current_pieces.size() == current_pieces.filter(func(piece: PuzzlePiece): return piece.active_areas.size() == 0).size()
		PuzzleMode.Mosaic:
			return current_pieces.size() == current_pieces.filter(func(piece: PuzzlePiece): return piece.full_area.collision_layer == 0).size()
			
	return false


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
				and piece_area.global_position.distance_to(current_side_area.global_position) < (source_piece.piece_size.x * 0.75):
				
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
				slave_piece.group_id = master_piece.group_id
				
				if reposition:
					match side:
						"top":
							reference_position.y -= master_piece.piece_size.y * side_direction
						"bottom":
							reference_position.y += master_piece.piece_size.y * side_direction
						"left":
							reference_position.x -= master_piece.piece_size.x * side_direction
						"right":
							reference_position.x += master_piece.piece_size.x * side_direction
					
					var group_adjust_offset: Vector2 = reference_position - slave_piece.global_position

					for smaller_group_piece: PuzzlePiece in smaller_group:
						smaller_group_piece.group_id = master_piece.group_id
						smaller_group_piece.global_position += group_adjust_offset


func _calculate_piece_size(puzzle_image: Image) -> Vector2i:
	var image_size: Vector2i = puzzle_image.get_size()
	var y: float = sqrt( ((image_size.y * number_of_pieces ) / image_size.x) )

	return Vector2i.ONE * ceili(image_size.y / y)
	
	
func _calculate_piece_size_by_aspect_ratio(puzzle_image: Image) -> Vector2i:
	var image_size: Vector2i = puzzle_image.get_size()

	var pieces_per_row: int = ceili(sqrt(number_of_pieces * (image_size.x / image_size.y)))
	var pieces_per_col: int = ceili(number_of_pieces / pieces_per_row)
	
	var piece_width: int = floori(image_size.x / pieces_per_row)
	var piece_height: int = floori(image_size.y / pieces_per_col)
	
	if puzzle_mode == PuzzleMode.Free:
		piece_width = piece_width * (1.0 - piece_margin)
		piece_height = piece_height * (1.0 - piece_margin)
	
	return Vector2i(piece_width, piece_height)


func _calculate_piece_rect(horizontal_piece: int, vertical_piece: int, size: Vector2i, margin: Vector2) -> Rect2:
	return Rect2(
		horizontal_piece * size.x - margin.x, 
		vertical_piece * size.y - margin.y, 
		size.x + ( 2 * margin.x), 
		size.y + ( 2 * margin.y)
	)
	

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

func _prepare_background_puzzle_transparent_texture(puzzle_piece_size: Vector2, horizontal_pieces: int, vertical_pieces: int) -> Vector2:
	if background_puzzle and background_puzzle.is_inside_tree():
		background_puzzle.queue_free()
		
	background_puzzle = Sprite2D.new()
	background_puzzle.name = "TransparentBackgroundPuzzle"
	background_puzzle.texture = puzzle_texture
	background_puzzle.self_modulate.a8 = background_mosaic_transparency
	background_puzzle.centered = true
	output_node.add_child(background_puzzle)
	background_puzzle.z_index = current_pieces.front().z_index - 1
	background_puzzle.scale = Vector2(puzzle_piece_size.x * horizontal_pieces, puzzle_piece_size.y * vertical_pieces) / puzzle_texture.get_size()
	## This is the final size scaled to position the puzzle mosaic that displays the puzzle as background
	
	return (puzzle_texture.get_size() * background_puzzle.scale) / 2.0

#endregion

func on_piece_dragged(piece: PuzzlePiece) -> void:
	if not draggable_component.is_dragging:
		match puzzle_mode:
			PuzzleMode.Free:
				var group_pieces: Array[PuzzlePiece] = pieces_from_group(piece.group_id)
				draggable_component.draggable = piece
				draggable_component.set_draggable_linked_group(group_pieces)
				draggable_component.start_drag()
				
				for active_piece: PuzzlePiece in group_pieces:
					active_piece.call_deferred("border_areas_detection_mode")

			PuzzleMode.Mosaic:
				draggable_component.draggable = piece
				draggable_component.start_drag()


func on_piece_released(piece: PuzzlePiece) -> void:
	draggable_component.release_drag()
	draggable_component.draggable = null
	
	match puzzle_mode:
		PuzzleMode.Free:
			detect_pieces_connections(piece)
			
			for puzzle_piece: PuzzlePiece in current_pieces:
				 ## TODO - Performance is not affected yet but could be if we reposition on this point with too many pieces
				detect_pieces_connections(puzzle_piece, true)
				await get_tree().physics_frame
				
				for area: Area2D in puzzle_piece.active_areas.filter(func(area: Area2D): return not area.is_queued_for_deletion()):
					puzzle_piece.call_deferred("border_areas_detected_mode")
			
		PuzzleMode.Mosaic:
			var mosaic_areas: Array[PuzzleMosaicArea] = []
			mosaic_areas.assign(piece.full_area.get_overlapping_areas())
			
			for mosaic_area: PuzzleMosaicArea in mosaic_areas:
				if mosaic_area.puzzle_piece == piece:
					piece.global_transform = mosaic_area.global_transform
					piece.disable_full_area()
					break
			
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if is_puzzle_finished():
		puzzle_finished.emit()
