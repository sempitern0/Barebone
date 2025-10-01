class_name VaultSavedGame extends RefCounted

var data: Dictionary = {
	"core": {
		"file_name": "",
		"file_path": "",
		"extension": "",
		"version_control": ProjectSettings.get_setting("application/config/version", "1.0.0"),
		"engine_version": "Godot %s" % Engine.get_version_info().string,
		"device": OS.get_distribution_name(),
		"platform:": OS.get_name(),
		"video_adapter_name": RenderingServer.get_video_adapter_name(),
		"processor_name": OS.get_processor_name(),
		"processor_count": OS.get_processor_count(),
		"creation_timestamp": "",
		"creation_date": "",
		"last_timestamp" : "",
		"last_datetime" : 0
	}
}


func _init(file_name: String, file_path: String, save_data: Dictionary = {}, new_save: bool = true) -> void:
	update(save_data)
	
	if new_save:
		data.core.file_name = file_name
		data.core.file_path = file_path
		data.core.extension = file_name.get_extension()
		data.core.creation_timestamp = Time.get_unix_time_from_system()
		data.core.creation_date = datetime()
		update_timestamp()


func update(new_data: Dictionary = {}) -> void:
	if not new_data.is_empty():
		_merge_data_recursive(data, new_data)


func update_timestamp():
	data.core.last_timestamp = Time.get_unix_time_from_system()
	data.core.last_datetime = datetime()


func datetime() -> String:
	### Example dict from system return { "year": 2024, "month": 1, "day": 25, "weekday": 4, "hour": 13, "minute": 34, "second": 18, "dst": false }
	var datetime = Time.get_datetime_dict_from_system()
	
	return "%s/%s/%s %s:%s" % [str(datetime.day).pad_zeros(2), str(datetime.month).pad_zeros(2), datetime.year, str(datetime.hour).pad_zeros(2), str(datetime.minute).pad_zeros(2)]

	
func _merge_data_recursive(dest: Dictionary, source: Dictionary) -> void:
	for key in source:
		if source[key] is Dictionary:
			if not dest.has(key):
				dest[key] = {}
				
			_merge_data_recursive(dest[key], source[key])
		else:
			dest[key] = source[key]
