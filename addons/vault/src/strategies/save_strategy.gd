class_name VaultSaveStrategy extends RefCounted

var save_file_path: String
var save_filename: String
var encrypted_key: StringName

func _init(file_path: String, filename: String, _encrypted_key: StringName = &"") -> void:
	save_file_path = file_path.trim_suffix("/")
	save_filename =  clean_filename(filename.get_basename().to_lower().strip_edges())
	encrypted_key = _encrypted_key
	
	assert(not save_file_path.is_empty(), "VaultSaveStrategy: The file path is empty")
	assert(save_file_path.is_absolute_path(), "VaultSaveStrategy: The file path to save is not absolute")
	assert(DirAccess.dir_exists_absolute(save_file_path), "VaultSaveStrategy: The file path does not exist in this system")


func load_file() -> VaultSavedGame:
	return null


func save_file(saved_game: VaultSavedGame) -> bool:
	return false
	

func delete_file() -> bool:
	return false


func extension_on_save() -> String:
	return ""


func save_exists() -> bool:
	return false
	

func save_path() -> String:
	return "%s/%s.%s" % [save_file_path, save_filename, extension_on_save()]


func clean_filename(string: String, include_numbers: bool = true) -> String:
	var regex = RegEx.new()
	
	if include_numbers:
		regex.compile("[\\p{L}\\p{N} ]*")
	else:
		regex.compile("[\\p{L} ]*")
	
	var result = ""
	var matches = regex.search_all(string)
	
	for m in matches:
		for s in m.strings:
			result += s
			
	return result
