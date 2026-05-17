@tool
extends AudioStreamPlayer
class_name Player

@export var playback : Playback:
	set = set_playback

var _updating : bool
var _track : DBTrack
var _progress : float


func _init() -> void:
	finished.connect(_on_finished)

func _validate_property(property : Dictionary) -> void:
	const HIDED_PROPS : Array[StringName] = [
		&'stream',
		&'playing', &'autoplay', &'stream_paused', &'max_polyphony',
		&'playback_type', &'volume_db', &'pitch_scale', &'mix_target',
	]
	if property.name in HIDED_PROPS:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _process(_delta) -> void:
	if stream and playing:
		_progress = clampf(get_playback_position() / stream.get_length(), 0, 1)
		if playback and playback.track == _track:
			if _progress != playback.progress:
				# FIXME это ломает воспроизведение,
				# если проигрывателей Player больше одного для одного и того же воспроизведения Playback
				playback.set_progress(_progress)

func set_playback(value : Playback) -> void:
	if playback:
		playback.playback_changed.disconnect(queue_update)
		playback.progress_changed.disconnect(_on_playback_progress_changed)
		playback.playing_changed.disconnect(_on_playback_playing_changed)
		playback.volume_changed.disconnect(_on_playback_volume_changed)
	
	playback = value
	
	if playback:
		playback.playback_changed.connect(queue_update.unbind(2))
		playback.progress_changed.connect(_on_playback_progress_changed.unbind(1))
		playback.playing_changed.connect(_on_playback_playing_changed.unbind(1))
		playback.volume_changed.connect(_on_playback_volume_changed.unbind(1))
	stop()
	queue_update()

func queue_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _on_playback_progress_changed() -> void:
	if playback.track == _track:
		if playback.progress != _progress:
			_progress = playback.progress
			if stream:
				if not playing and not stream_paused:
					play()
				stream_paused = not playback.playing
				seek(_progress * stream.get_length())

func _on_playback_playing_changed() -> void:
	assert(playback)
	if stream:
		if playback.track == _track:
			_progress = playback.progress
			if not playing and not stream_paused:
				play()
			stream_paused = not playback.playing
			seek(_progress * stream.get_length())

func _on_playback_volume_changed() -> void:
	volume_db = linear_to_db(playback.volume)

func _on_finished() -> void:
	play()
	stream_paused = true
	seek(stream.get_length())
	_progress = 1.0
	if playback and playback.track == _track:
		if playback.progress != _progress:
			playback.set_progress(_progress)

func _update() -> void:
	if not _updating:
		return
	
	if playback and not Engine.is_editor_hint():
		volume_db = linear_to_db(playback.volume)
		
		if playback.track != _track:
			
			_track = playback.track
			
			var stream_mp3 : AudioStreamMP3
			if _track:
				if ResourceLoader.has_cached(_track.file_path):
					stream_mp3 = ResourceLoader.load(_track.file_path)
				elif FileAccess.file_exists(_track.file_path):
					var bytes : PackedByteArray = FileAccess.get_file_as_bytes(_track.file_path)
					var err : Error = FileAccess.get_open_error()
					if err == OK:
						if bytes:
							stream_mp3 = AudioStreamMP3.load_from_buffer(bytes)
							if stream_mp3.get_length() > 0:
								stream_mp3.set_path_cache(_track.file_path)
							else:
								stream_mp3 = null
								push_warning('Ошибка загрузки трека "', _track.file_path, '": Трек пустой')
						else:
							push_warning('Ошибка загрузки трека "', _track.file_path, '": Файл пустой')
					else:
						push_warning('Ошибка загрузки трека "', _track.file_path, '": Ошибка: "', error_string(err), '"')
			
			if stream_mp3:
				stream = stream_mp3
				_progress = playback.progress
				play()
				stream_paused = not playback.playing
				seek(_progress * stream.get_length())
			
			else:
				stream = null
	
	elif stream:
		stream = null
	
	_updating = false
