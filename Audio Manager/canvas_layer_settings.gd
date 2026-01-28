extends CanvasLayer
class_name CanvasLayerSettings

@onready var _scene_volume : PackedScene = preload("res://Audio Manager/Components/h_box_container_slider.tscn")
@onready var _scene_output : PackedScene = preload("res://Audio Manager/Components/h_box_container_output.tscn")
@onready var _scene_input : PackedScene = preload("res://Audio Manager/Components/h_box_container_input.tscn")
@onready var _vbox = $Panel/Panel/VBoxContainer/TabContainer/Audio/HBoxContainer/VBoxContainer

func _ready() -> void:
	var output : AudioOutput = _scene_output.instantiate()
	_vbox.add_child(output)
	var input : AudioInput = _scene_input.instantiate()
	_vbox.add_child(input)
	for b in range(0, AudioServer.bus_count):
		var instance : VolumeSlider = _scene_volume.instantiate()
		instance._name = AudioServer.get_bus_name(b)
		_vbox.add_child(instance)
