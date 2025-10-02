class_name RollingNumberRichTextLabel extends RichTextLabel

signal started
signal ended

@export var default_duration: float = 2.0
@export var delay: float = 0.05
@export var tween_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var tween_transition: Tween.TransitionType = Tween.TRANS_LINEAR

var tween: Tween


## Display callback allow custom outputs for the rich text label text
func roll(from: int, to: int, duration: float = default_duration, display_callback: Callable = set_number) -> void:
	if _tween_can_be_created():
		started.emit()
		
		tween = create_tween()\
			.set_ease(tween_ease)\
			.set_trans(tween_transition)
		
		tween.tween_method(display_callback, from, to, duration).set_delay(delay)
		tween.finished.connect(func(): ended.emit(), CONNECT_ONE_SHOT)
		

func pause() -> void:
	if tween and tween.is_running():
		tween.pause()


func play() -> void:
	if tween:
		tween.play()


func set_number(value: int) -> void:
	var pretty_number: Dictionary = OmniKitStringHelper.pretty_number_as_dict(value)
	
	text = "%1.0f%s" % [pretty_number.number, pretty_number.suffix]


func _tween_can_be_created() -> bool:
	return tween == null or (tween != null and not tween.is_running())
