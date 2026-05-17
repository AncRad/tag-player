extends Control

@export var playback : Playback:
	set = set_playback

@export_group('inner')
@export var pause_button : Button
@export var play_button : Button


func set_playback(value : Playback) -> void:
	if playback != value:
		if playback:
			playback.playing_changed.disconnect(_on_playback_playing_changed)
		
		playback = value
		
		if playback:
			playback.playing_changed.connect(_on_playback_playing_changed)
		_on_playback_playing_changed()

func _on_playback_playing_changed(_playing = null) -> void:
	var playing : bool
	if playback:
		playing = playback.playing
	play_button.visible = not playing
	pause_button.visible = playing

func _on_prev_button_pressed() -> void:
	if playback:
		playback.play(-1)

func _on_stop_button_pressed() -> void:
	if playback:
		playback.stop()

func _on_pause_button_pressed() -> void:
	if playback:
		playback.pause()

func _on_play_button_pressed() -> void:
	if playback:
		playback.unpause()

func _on_next_button_pressed() -> void:
	if playback:
		playback.play(+1)
