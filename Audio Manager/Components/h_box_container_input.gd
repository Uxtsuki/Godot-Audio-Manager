extends HBoxContainer
class_name AudioInput

func _ready() -> void:
	for o in AudioManager._list_input():
		$OptionButton.add_item(o)
	if AudioManager._list_input().size() > 0 && AudioManager._config_file:
		$OptionButton.selected = AudioManager._list_input().find(AudioManager._config_file.get_value("audio", "input", "Default"))

func _on_option_button_item_selected(index: int) -> void:
	AudioManager._change_input(AudioManager._list_input()[index])
