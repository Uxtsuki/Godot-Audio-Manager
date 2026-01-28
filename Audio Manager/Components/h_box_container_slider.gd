extends HBoxContainer
class_name VolumeSlider

@export var _name : String = ""
@onready var _rich_text_label_name : RichTextLabel = $RichTextLabelName
@onready var _rich_text_label_value : RichTextLabel = $RichTextLabelValue
@onready var _hslider_volume : HSlider = $HSlider

func _ready() -> void:
	_rich_text_label_name.text ="{x} Volume".format({"x": _name.capitalize()})
	if AudioManager._config_file:
		_hslider_volume.value = AudioManager._config_file.get_value("audio", "{x}_volume".format({"x": _name.to_lower()}), 1) * 100
	_rich_text_label_value.text = str(int(_hslider_volume.value)) + "%"
	
func _on_h_slider_value_changed(value: float) -> void:
	AudioManager._change_volume(_name, value)
	AudioManager._save()
	_rich_text_label_value.text = str(int(value)) + "%"

func _on_h_slider_drag_ended(value_changed: bool) -> void:
	AudioManager._save()
