extends Node

##@author: Uxtsuki
##@year 2026
const CONFIG_FILE_PATH : String = "res://config.cfg"
const CONFIG_FILE_PASS : String = "1234"
var _config_file : ConfigFile

const MAX_SOUND_PLAYERS : int = 1
const MAX_SOUND_PLAYERS_2D : int = 1
const MAX_SOUND_PLAYERS_3D : int = 1

var _music_player : AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _musics : Array[AudioStream] = [
	preload("res://audio.wav")
]
@export var _random_music : bool = false
@export var _music_index : int = 0

var _sound_players : Array[Array] = []
var _sound_players_2d : Array[Array] = []
var _sound_players_3d : Array[Array] = []

enum SOUND_TYPES { AMBIENT, UI, GENERAL, VOIP }
@onready var _sounds : Dictionary = {
	"a": preload("res://audio.wav")
}

var _input_player : AudioStreamPlayer = AudioStreamPlayer.new()
var _input_capture_effect : AudioEffectCapture = AudioEffectCapture.new()
var _audio_recording : AudioStreamWAV = AudioStreamWAV.new()
var _input_record_effect : AudioEffectRecord = AudioEffectRecord.new()

var _input_microphone : AudioStreamPlayer = AudioStreamPlayer.new()
var _playback : AudioStreamGeneratorPlayback

func _load() -> void:
	if !_config_file:
		_config_file = ConfigFile.new()
	#if FileAccess.file_exists(CONFIG_FILE_PATH):
	#	_config_file.save_encrypted_pass(CONFIG_FILE_PATH, CONFIG_FILE_PASS)

	_config_file.load_encrypted_pass(CONFIG_FILE_PATH, CONFIG_FILE_PASS)
	AudioServer.set_bus_volume_linear(0, _config_file.get_value("audio", "master_volume", 1))
	AudioServer.set_bus_volume_linear(1, _config_file.get_value("audio", "music_volume", 1))
	AudioServer.set_bus_volume_linear(2, _config_file.get_value("audio", "ambient_volume", 1))
	AudioServer.set_bus_volume_linear(3, _config_file.get_value("audio", "ui_volume", 1))
	AudioServer.set_bus_volume_linear(4, _config_file.get_value("audio", "general_volume", 1))
	AudioServer.set_bus_volume_linear(5, _config_file.get_value("audio", "void_volume", 1))
	AudioServer.set_bus_volume_linear(6, _config_file.get_value("audio", "input_volume", 0))

func _save() -> void:
	if !_config_file:
		_load()
	_config_file.set_value("audio", "master_volume", AudioServer.get_bus_volume_linear(0))
	_config_file.set_value("audio", "music_volume", AudioServer.get_bus_volume_linear(1))
	_config_file.set_value("audio", "ambient_volume", AudioServer.get_bus_volume_linear(2))
	_config_file.set_value("audio", "ui_volume", AudioServer.get_bus_volume_linear(3))
	_config_file.set_value("audio", "general_volume", AudioServer.get_bus_volume_linear(4))
	_config_file.set_value("audio", "voip_volume", AudioServer.get_bus_volume_linear(5))
	_config_file.set_value("audio", "input_volume", AudioServer.get_bus_volume_linear(6))
	_config_file.save_encrypted_pass(CONFIG_FILE_PATH, CONFIG_FILE_PASS)

func _reset() -> void:
	if FileAccess.file_exists(CONFIG_FILE_PATH):
		DirAccess.remove_absolute(CONFIG_FILE_PATH)
	for counter in range(AudioServer.bus_count, 0):
		if counter == 0:
			AudioServer.set_bus_volume_linear(0, 1)
		else:
			AudioServer.remove_bus(counter)
	
	_sound_players = []
	_sound_players_2d = []
	_sound_players_3d = []

	_add_busses()
	_load()
	_add_players("AudioStreamPlayer", MAX_SOUND_PLAYERS, _sound_players)
	_add_players("AudioStreamPlayer2D", MAX_SOUND_PLAYERS_2D, _sound_players_2d)
	_add_players("AudioStreamPlayer3D", MAX_SOUND_PLAYERS_3D, _sound_players_3d)

func _add_busses() -> void:
	AudioServer.add_bus()
	AudioServer.set_bus_name(1, "Music")
	AudioServer.set_bus_send(1, "Master")
	AudioServer.add_bus()
	AudioServer.set_bus_name(2, "Ambient")
	AudioServer.set_bus_send(2, "Master")
	AudioServer.add_bus()
	AudioServer.set_bus_name(3, "UI")
	AudioServer.set_bus_send(3, "Master")
	AudioServer.add_bus()
	AudioServer.set_bus_name(4, "General")
	AudioServer.set_bus_send(4, "Master")
	AudioServer.add_bus()
	AudioServer.set_bus_name(5, "Voip")
	AudioServer.set_bus_send(5, "Master")
	AudioServer.add_bus()
	AudioServer.set_bus_name(6, "Input")
	AudioServer.add_bus_effect(6, _input_capture_effect, 0)
	AudioServer.add_bus_effect(6, _input_record_effect, 1)
	#AudioServer.set_bus_send(6, "Master")

func _play_music(_index : int = 0) -> void:
	if _musics.size() <= _index:
		return
	_music_index = _index
	_music_player.stream = _musics[_music_index]
	_music_player.play()

func _music_finished() -> void:
	if _random_music:
		_music_index = randi_range(0, _musics.size() - 1)
	else:
		_music_index = wrapi(_music_index + 1, 0, _musics.size() - 1)
	_play_music(_music_index)
	
func _play_sound(_sound_name : String, _players : Array, _priority : bool = true) -> Variant:
	if !_sounds.has(_sound_name):
		return null
	var player = null

	for p in _players:
		if !p.playing:
			player = p
			break
		elif _priority:
			if !player || (player.get_playback_position() / player.stream.get_length()) < (p.get_playback_position() / p.stream.get_length()):
				player = p
	if player:
		player.stream = _sounds[_sound_name]
	return player

func _play_2d(
	_sound_name : String,
	_at : Vector2,
	_direction : Vector2,
	_type : SOUND_TYPES = SOUND_TYPES.GENERAL,
	_priority : bool = true,
	_playback_position : float = 0,
	_area_mask : int = -1,
	_attenuation : Variant = null,
	_max_distance : float = 0,
	_panning_strength : float = 1,
	_pitch_scale : float = 1,
	_max_db : float = -1,
	_local_volume : float = 1
	) -> void:
	var audio_player : AudioStreamPlayer2D = _play_sound(_sound_name, _sound_players_2d[_type], _priority)
	if audio_player && get_tree() && get_tree().current_scene:
		if audio_player.get_parent():
			audio_player.get_parent().remove_child(audio_player)
		get_tree().current_scene.add_child(audio_player)
		audio_player.global_position = _at
		audio_player.look_at(_direction)
		audio_player.volume_linear = _local_volume

		if _area_mask:
			audio_player.area_mask = _area_mask
		if _attenuation:
			audio_player.attenuation = _attenuation

		audio_player.max_distance = _max_distance
		audio_player.panning_strength = _panning_strength
		audio_player.pitch_scale = _pitch_scale

		audio_player.play(_playback_position)


func _play_3d(
	_sound_name : String,
	_at : Vector3,
	_direction : Vector3,
	_type : SOUND_TYPES = SOUND_TYPES.GENERAL,
	_priority : bool = true,
	_playback_position : float = 0,
	_area_mask : int = -1,
	_attenuation : AudioStreamPlayer3D.AttenuationModel = -1,
	_attenuation_cutoff : Variant = null,
	_attenuation_filter_db : Variant = null,
	_unit_size : float = 10,
	_doppler : AudioStreamPlayer3D.DopplerTracking = -1,
	_emission_angle : Variant = null,
	_emission_attenuation: Variant = null,
	_max_distance : float = 0,
	_panning_strength : float = 1,
	_pitch_scale : float = 1,
	_max_db : float = -1,
	_local_volume : float = 1
	) -> void:
	var audio_player : AudioStreamPlayer3D = _play_sound(_sound_name, _sound_players_3d[_type], _priority)
	if audio_player && get_tree() && get_tree().current_scene:
		if audio_player.get_parent():
			audio_player.get_parent().remove_child(audio_player)
		get_tree().current_scene.add_child(audio_player)
		audio_player.global_position = _at
		audio_player.look_at(_direction)
		audio_player.volume_linear = _local_volume

		if _area_mask:
			audio_player.area_mask = _area_mask
		if _attenuation:
			audio_player.attenuation_model = _attenuation
		if _attenuation_cutoff:
			audio_player.attenuation_filter_cutoff_hz = _attenuation_cutoff
		if _attenuation_filter_db:
			audio_player.attenuation_filter_db = _attenuation_filter_db
		if _doppler:
			audio_player.doppler_tracking = _doppler
		if _emission_angle:
			audio_player.emission_angle_enabled = true
			audio_player.emission_angle_degrees = _emission_angle
		if _emission_attenuation:
			audio_player.emission_angle_filter_attenuation_db = _emission_attenuation

		audio_player.unit_size = _unit_size
		audio_player.max_distance = _max_distance
		audio_player.panning_strength = _panning_strength
		audio_player.pitch_scale = _pitch_scale

		if _max_db:
			audio_player.max_db = _max_db
		audio_player.play(_playback_position)

func _play_audio(
	_sound_name : String,
	_type : SOUND_TYPES = SOUND_TYPES.GENERAL,
	_priority : bool = true,
	_playback_position : float = 0,
	_local_volume : float = 1
	) -> void:
	var audio_player : AudioStreamPlayer = _play_sound(_sound_name, _sound_players[_type], _priority)
	if audio_player && get_tree() && get_tree().current_scene:
		if audio_player.get_parent():
			audio_player.get_parent().remove_child(audio_player)
		get_tree().current_scene.add_child(audio_player)
		audio_player.volume_linear = _local_volume

		audio_player.play(_playback_position)

func _add_players(_class : String, _number : int, _array : Array) -> void:
	for t in SOUND_TYPES:
		_array.append([])
		for n in range(0, _number):
			var player = ClassDB.instantiate(_class)
			player.autoplay = false
			player.bus = t.capitalize()
			player.max_polyphony = 2
			_array[SOUND_TYPES.get(t)].append(player)
			if n >= _number: break

func _change_volume(_name : String = "Master", _volume : float = 100) -> void:
	var _index : int = 0
	match _name:
		"Music":
			_index = 1
		"Ambient":
			_index = 2
		"UI":
			_index = 3
		"General":
			_index = 4
		"Voip":
			_index = 5
		"Input":
			_index = 6
		_:
			_index = 0
			_name = "Master"
	AudioServer.set_bus_volume_linear(_index, _volume / 100.0)
	_config_file.set_value("audio", "{x}_volume".format({"x": _name.to_lower()}), _volume / 100.0)

func _list_output() -> PackedStringArray:
	return AudioServer.get_output_device_list()

func _change_output(_name : String) -> void:
	AudioServer.output_device = _name
	_config_file.set_value("audio", "output", _name)
	_save()

func _list_input() -> PackedStringArray:
	return AudioServer.get_input_device_list()

func _change_input(_name : String) -> void:
	AudioServer.input_device = _name
	_config_file.set_value("audio", "input", _name)
	_save()

func _ready() -> void:
	_add_busses()
	_load()

	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.bus = "Music"
	_music_player.finished.connect(_music_finished)
	add_child(_music_player)

	_input_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_input_player.bus = "Input"
	_input_microphone.bus = "Input"
	add_child(_input_player)
	_input_microphone.stream = AudioStreamMicrophone.new()
	add_child(_input_microphone)

	_add_players("AudioStreamPlayer", MAX_SOUND_PLAYERS, _sound_players)
	_add_players("AudioStreamPlayer2D", MAX_SOUND_PLAYERS_2D, _sound_players_2d)
	_add_players("AudioStreamPlayer3D", MAX_SOUND_PLAYERS_3D, _sound_players_3d)

func _process(delta: float) -> void:
	#if is_multiplayer_authority() && _input_capture_effect.can_get_buffer(512) && _playback && _playback.can_push_buffer(512):
	#	_send_audio_data(_input_capture_effect.get_buffer(512))
	#	_input_capture_effect.clear_buffer()

	if Input.is_action_just_released("Microphone"):
		_input_record_effect.set_recording_active(false)
		_audio_recording = _input_record_effect.get_recording()
		_audio_recording.save_to_wav("res://audio.wav")
		_input_microphone.stop()
	elif Input.is_action_just_pressed("Microphone"):
		_input_record_effect.set_recording_active(true)
		_input_microphone.play()

## TODO: ENetConnection
func _enter_tree() -> void:
	#set_multiplayer_authority()
	pass

func _peer_connected(peer : int) -> void:
	_add_players("AudioStreamPlayer Depends", 1, [])
	pass

func _send_audio_data(data : PackedVector2Array) -> void:
	pass

func _receive_audio_data(peer : int, data : PackedVector2Array) -> void:
	_playback = _sound_players[SOUND_TYPES.VOIP][peer].get_stream_playback()
	for i in range(0, data.size() - 1):
		_playback.push_frame(data[i])
