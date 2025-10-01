class_name VaultSaveStrategyJson extends VaultSaveStrategy


func load_file() -> VaultSavedGame:
	if save_exists():
		return VaultSavedGame.new(save_filename, save_file_path, _parse(save_path()), false)
	
	return null


func save_file(saved_game: VaultSavedGame) -> bool:
	var file_access: FileAccess = FileAccess.open(save_path(), FileAccess.WRITE) if encrypted_key.is_empty() else FileAccess.open_encrypted_with_pass(save_path(), FileAccess.WRITE, encrypted_key)
	var open_error: Error = FileAccess.get_open_error()
	
	if open_error != OK:
		printerr(error_string(open_error))
		push_error("VaultSaveStrategyJson: An error %s happened saving file %s" % [error_string(open_error), save_path()])
		return false
	
	saved_game.data.core.extension = extension_on_save()
	saved_game.update_timestamp()
	file_access.store_string(JSON.stringify(saved_game.data))
	file_access.close()
	
	return true


func delete_file() -> bool:
	if save_exists():
		var error = DirAccess.remove_absolute(save_path())
		
		if error != OK:
			push_error("VaultSaveStrategyJson: An error %s happened trying to delete the file %s" % [error_string(error), save_filename])

	return false


func extension_on_save() -> String:
	return "json"


func save_exists() -> bool:
	return FileAccess.file_exists(save_path())
	

func _parse(path: String) -> Variant:
	if not path.get_extension() == extension_on_save():
		push_error("VaultSaveStrategyJson: The file path %s provided does not have a valid JSON extension" % path)
		return {}
	
	var file: FileAccess
	
	if encrypted_key.is_empty():
		file = FileAccess.open(path, FileAccess.READ)
	else:
		print("open json with ", encrypted_key)
		file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, encrypted_key)
		
	var open_error: Error = FileAccess.get_open_error()
	
	if open_error != OK:
		push_error("VaultSaveStrategyJson: An error happened opening json file %s, Error %d-%s" % [path, open_error, error_string(open_error)])
		return {}
	
	var json = JSON.new()
	var json_string_data: String = file.get_as_text()
	var json_error: Error = json.parse(json_string_data)
	
	if json_error == OK:
		assert(json.data is Array or json.data is Dictionary, "VaultSaveStrategyJson: Invalid data type, only JSON dictionary or arrays are supported")
	else:
		push_error("VaultSaveStrategyJson: JSON Parse Error: ", json.get_error_message(), " in ", json_string_data, " at line ", json.get_error_line())

	return json.data
