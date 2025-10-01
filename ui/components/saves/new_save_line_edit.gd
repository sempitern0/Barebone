class_name NewSaveGameLineEdit extends LineEdit

signal created_new_save(new_save: VaultSavedGame)

@export var action_to_submit: StringName = &"ui_accept"


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(action_to_submit):
		create_new_save()


func _ready() -> void:
	set_process_unhandled_input(visible)
	
	visibility_changed.connect(on_visibility_changed)
	text_changed.connect(on_text_changed)
	text_submitted.connect(on_text_submitted)
	
	
func create_new_save() -> void:
	if filename_is_valid(text):
		set_process_unhandled_input(false)
		editable = false
	
		VaultSaveManager.make_current(VaultSaveManager.create_new_save(text))
		VaultSaveManager.save_game(VaultSaveManager.current_saved_game)
		
		created_new_save.emit(VaultSaveManager.current_saved_game)
		print_rich("[b]NewSaveGame:[/b] [color=green]Created[/color] a new save game on [color=yellow][i]%s[/i][/color]" % VaultSaveManager.default_path)


func filename_is_valid(filename: String) -> bool:
	var is_valid: bool = true
	
	for character: String in filename:
		if character in OmniKitStringHelper.AsciiPunctuation:
			is_valid = false
			break
	
	if not is_valid:
		text = filename.left(filename.length() - 1)
		caret_column = text.length()
	
	return is_valid


func on_text_changed(new_text: String) -> void:
	filename_is_valid(new_text)
		

func on_text_submitted(_filename: String) -> void:
	create_new_save()

@warning_ignore("unused_parameter")
func on_error_creating_save_game(filename: String, error: Error) -> void:
	pass


func on_visibility_changed() -> void:
	set_process_unhandled_input(visible)
	
	if visible:
		grab_focus()
	else:
		release_focus()
		clear()
