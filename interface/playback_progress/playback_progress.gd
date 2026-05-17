extends ProgressBar

@export var playback : Playback: set = set_playback

var _grabbed : bool


func _notification(what : int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			value = 0
		
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_EXIT_TREE, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_grabbed = false

func _ready() -> void:
	_notification(NOTIFICATION_SCENE_INSTANTIATED)

func _gui_input(event : InputEvent) -> void:
	if event.is_action_pressed('playback_progress_volume_up', true):
		playback.volume = clampf(playback.volume * 1.1, 0.001, 1)
	elif event.is_action_pressed('playback_progress_volume_down', true):
		playback.volume = clampf(playback.volume / 1.1, 0.001, 1)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and not _grabbed:
				_grabbed = true
			
			elif not event.is_pressed() and _grabbed:
				_grabbed = false
				value = clampf(event.position.x / size.x, 0, 1)
				if playback:
					playback.set_progress(value)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _grabbed and event.is_pressed():
				_grabbed = false
				if playback:
					value = playback.progress
	
	elif event is InputEventMouseMotion:
		if _grabbed:
			value = clampf(event.position.x / size.x, 0, 1)

func set_playback(p_value : Playback) -> void:
	if p_value != playback:
		if playback:
			playback.progress_changed.disconnect(_on_playback_progress_changed)
		
		playback = p_value
		
		if playback:
			p_value.progress_changed.connect(_on_playback_progress_changed)

func _on_playback_progress_changed(_progress : float) -> void:
	if not _grabbed:
		value = playback.progress
