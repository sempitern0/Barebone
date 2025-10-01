class_name VolumePercentageLabel extends Label

@export var audio_slider: AudioSlider


func _ready() -> void:
	text = str(roundi(audio_slider.value * 100)) + " %"
	audio_slider.value_changed.connect(on_updated_bus_volume)
	

func on_updated_bus_volume(new_value: float) -> void:
	text = str(roundi(new_value * 100)) + " %"
