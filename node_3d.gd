extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$"Camera3D".global_position += Vector3.LEFT * delta * 2


func _on_timer_timeout() -> void:
	AudioManager._play_3d(
		"a",
		$MeshInstance3D.global_position,
		$Camera3D.global_position,
		AudioManager.SOUND_TYPES.AMBIENT,
		true,
		0,
		-1,
		AudioStreamPlayer3D.AttenuationModel.ATTENUATION_LOGARITHMIC,
		null,
		null,
		10,
		AudioStreamPlayer3D.DopplerTracking.DOPPLER_TRACKING_IDLE_STEP,
		45,
		0,
		500,
		1,
		1,
		-1
	)
