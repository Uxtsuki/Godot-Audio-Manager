extends Node2D

func _ready() -> void:
	#AudioManager._play_music(0)
	pass

func _input(event: InputEvent) -> void:
	$Camera2D.global_position = get_global_mouse_position()


func _on_timer_timeout() -> void:
	
	#AudioManager._play_audio(
	#"a",
	#	AudioManager.SOUND_TYPES.UI
	#)
	
	AudioManager._play_2d(
		"a",
		$Sprite2D.global_position,
		$Camera2D.global_position,
		AudioManager.SOUND_TYPES.GENERAL,
		true,
		0,
		-1,
		0.8,
		2000,
		1,
		1,
		-1
	)
