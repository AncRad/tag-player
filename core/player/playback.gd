extends Resource
class_name Playback

signal track_changed(track : DBTrack)
signal list_changed(list : DBListNode)
signal playback_changed(track : DBTrack, list : DBListNode)
signal playing_changed(playing : bool)
signal progress_changed(progress : float)
signal volume_changed(volume : float)

@export var list : DBListNode:
	set = set_list
@export var track : DBTrack:
	set = set_track
@export var playing : bool:
	set = set_playing
@export var progress : float:
	set = set_progress
@export var volume : float = 1.0:
	set = set_volume


func play(offset : int = 0, p_track : DBTrack = track, p_list : DBListNode = list) -> void:
	list = p_list
	if offset == 0 and p_track:
		track = p_track
	
	elif list:
		track = find_track(list.get_tracks(), p_track, offset)
	
	progress = 0
	playing = track != null

func stop() -> void:
	playing = false
	progress = 0

func pause() -> void:
	playing = false

func unpause() -> void:
	if progress == 1.0:
		play(+1)
	else:
		playing = true

func play_pause() -> void:
	if playing:
		playing = false
	
	elif progress == 1.0:
		play(+1)
	else:
		playing = true

func set_list(value : DBListNode) -> void:
	if value != list:
		list = value
		list_changed.emit(list)
		playback_changed.emit(track, list)
		emit_changed()

func set_track(value : DBTrack) -> void:
	if value != track:
		track = value
		track_changed.emit(track)
		playback_changed.emit(track, list)
		emit_changed()

func set_playing(value : bool) -> void:
	if value != playing:
		if not track and value:
			play(+1)
		
		else:
			playing = value
			playing_changed.emit(playing)
			emit_changed()

func set_progress(value : float) -> void:
	assert(is_finite(value))
	value = clamp(value, 0.0, 1.0)
	if value != progress:
		progress = value
		progress_changed.emit(progress)
		if progress == 1.0 and playing:
			play(+1)

func set_volume(value : float) -> void:
	assert(is_finite(value))
	value = clamp(value, 0.0, 1.0)
	if value != volume:
		volume = value
		volume_changed.emit(volume)
		emit_changed()

static func find_track(tracks : Array[DBTrack], p_track : DBTrack, offset : int = 0) -> DBTrack:
	var track_index : int = tracks.find(p_track)
	if track_index == -1 or not p_track:
		if tracks:
			return tracks[0]
		else:
			return null
	
	else:
		return tracks[wrapi(track_index + offset, 0, tracks.size())]
