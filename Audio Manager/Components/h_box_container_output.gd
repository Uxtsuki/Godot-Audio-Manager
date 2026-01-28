extends HBoxContainer
class_name AudioOutput

func _ready() -> void:
	for o in AudioManager._list_output():
		$OptionButton.add_item(o)
	if AudioManager._list_output().size() > 0 && AudioManager._config_file:
		$OptionButton.selected = AudioManager._list_output().find(AudioManager._config_file.get_value("audio", "output", "Default"))

func _on_option_button_item_selected(index: int) -> void:
	AudioManager._change_output(AudioManager._list_output()[index])
