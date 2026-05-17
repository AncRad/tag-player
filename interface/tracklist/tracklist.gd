extends Control
class_name Tracklist

const THEME_TYPE : StringName = &'Tracklist'

signal scroll_changed(scroll : float)
signal scroll_progress_changed(scroll_progress : float)
signal selected_tracks_changed()
signal debug_string_changed(string : String)

@export var db_list : DBListNode:
	set = set_db_list

@export var playback : Playback:
	set = set_playback

@export var scroll : float:
	set = set_scroll

@export_range(0, 1, 0.00001)
var scroll_progress : float:
	set = set_scroll_progress,
	get = get_scroll_progress

var _track_drawer : TrackDrawer
var _track_drawer_updated : bool
var _debug_drawn : int
var _selected_tracks : Array[DBTrack]
var _rect_to_track : Dictionary[Rect2, DBTrack]
var _playback_track : DBTrack:
	set = _set_playback_track

var _selection : bool:
	set(value):
		if value != _selection:
			_selection = value
			_selection_tracks = []
			_selection_from = 0
			_selection_to = 0
var _selection_tracks : Array[DBTrack]
var _selection_from : int
var _selection_to : int


func _init() -> void:
	name = THEME_TYPE
	theme_changed.connect(_theme_changed)
	_track_drawer = TrackDrawer.new()
	_track_drawer.theme_type = THEME_TYPE
	_track_drawer.read_theme(self)

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_FOCUS_EXIT, NOTIFICATION_WORLD_2D_CHANGED:
			if _selection:
				_selection = false
		NOTIFICATION_EXIT_CANVAS, NOTIFICATION_VISIBILITY_CHANGED:
			if _selection:
				_selection = false

func _input(event: InputEvent) -> void:
	if _selection and event.is_action_released('tracklist_selection_begin'):
		accept_event()
		_selection = false

func _gui_input(event : InputEvent) -> void:
	var event_is_pointer : bool
	var event_position : Vector2
	var event_is_inside : bool
	if &'position' in event and (event.position is Vector2 or event.position is Vector2i):
		event_position = Vector2(event.position)
		event_is_pointer = true
		event_is_inside = Rect2(Vector2(), size).has_point(event_position)
	
	var accepted : bool
	
	if has_focus() and not event_is_pointer or event_is_inside:
		
		if event.is_action_pressed('tracklist_selection_invert'):
			accepted = true
			if db_list:
				var selected_tracks : Array[DBTrack]
				var selected_tracks_befor : Array[DBTrack] = get_selected_tracks()
				for track in db_list.get_tracks():
					if track not in selected_tracks_befor:
						selected_tracks.append(track)
				set_selected_tracks(selected_tracks)
			else:
				set_selected_tracks([] as Array[DBTrack])
		
		elif event.is_action_pressed('tracklist_selection_none'):
			accepted = true
			if not _selected_tracks and db_list and event.is_action_pressed('tracklist_selection_all'):
				set_selected_tracks(db_list.get_tracks())
			else:
				set_selected_tracks([] as Array[DBTrack])
		
		elif event.is_action_pressed('tracklist_selection_all'):
			accepted = true
			if not db_list or _selected_tracks and event.is_action_pressed('tracklist_selection_none'):
				set_selected_tracks([] as Array[DBTrack])
			else:
				set_selected_tracks(db_list.get_tracks())

		elif event.is_action('tracklist_selection_begin', true) and event_is_pointer:
			accepted = true
			if event.is_pressed() != _selection:
				if event.is_pressed():
					_selection = true
					_selection_tracks = get_selected_tracks(false)
					_selection_from = floori(scroll + event_position.y / _track_drawer.interval)
					_selection_to = _selection_from
				else:
					_selection = false
		
		elif event.is_action_pressed('tracklist_selection') and event_is_pointer:
			accepted = true
			var track : DBTrack = get_track_at_position(event_position)
			if track:
				var selected_tracks : Array[DBTrack] = get_selected_tracks()
				if track in selected_tracks:
					selected_tracks.erase(track)
					set_selected_tracks(selected_tracks)
				elif track:
					selected_tracks.append(track)
					set_selected_tracks(selected_tracks)
		
		elif event.is_action_pressed('tracklist_scroll_up', true):
			accepted = true
			scroll -= 1
		
		elif event.is_action_pressed('tracklist_scroll_down', true):
			accepted = true
			scroll += 1
		
		elif event.is_action_pressed('tracklist_play') and event_is_pointer:
			accepted = true
			if playback:
				var track : DBTrack = get_track_at_position(event_position)
				if track:
					playback.play(0, track, db_list)
	
	if _selection and event_is_pointer:
		accepted = true
		if Input.is_action_pressed('tracklist_selection_begin', true):
			_selection_to = floori(scroll + event_position.y / _track_drawer.interval)
			_selection_begin_update()
		else:
			_selection = false
	
	if accepted:
		accept_event()
		if event_is_inside:
			grab_focus()

func _draw() -> void:
	if not _track_drawer_updated:
		_track_drawer.read_theme(self)
		_track_drawer_updated = true
	
	scroll = clampf(scroll, 0, get_scroll_max())
	_rect_to_track.clear()
	
	# настроить шрифт для кеширования в (FontData)
	_track_drawer.font.set_cache_capacity(1000, 1000)
	
	var tracks : Array[DBTrack]
	if db_list:
		tracks = db_list.get_tracks()
	var track_number : int = floori(scroll)
	var pos_y : float = -wrapf(scroll, 0, 1) * _track_drawer.interval
	var draw_time : float = Time.get_ticks_usec()
	while pos_y < size.y and track_number < tracks.size():
		var track : DBTrack = tracks[track_number]
		var track_rect : Rect2 = Rect2(0, pos_y, size.x, _track_drawer.interval)
		
		if track in _selected_tracks:
			_track_drawer.background_selected.draw(get_canvas_item(), track_rect)
		else:
			_track_drawer.background_normal.draw(get_canvas_item(), track_rect)
		
		var track_font_color : Color
		if playback and track == playback.track:
			track_font_color = _track_drawer.font_color_playback
		else:
			track_font_color = _track_drawer.font_color_normal
		
		_track_drawer.draw_track(get_canvas_item(), track, track_rect, track_font_color)
		_rect_to_track[track_rect] = track
		
		track_number += 1
		pos_y += _track_drawer.interval
	
	_debug_drawn += 1
	debug_string_changed.emit(str(_debug_drawn, ': %4.d' % (Time.get_ticks_usec() - draw_time), ' мкс'))

func set_db_list(value : DBListNode) -> void:
	if value != db_list:
		if db_list:
			db_list.list_changed.disconnect(_on_db_list_changed)
		
		db_list = value
		
		if db_list:
			db_list.list_changed.connect(_on_db_list_changed)
		_on_db_list_changed()

func set_playback(value : Playback) -> void:
	if value != playback:
		if playback:
			playback.track_changed.disconnect(_on_playback_track_changed)
		
		playback = value
		
		if playback:
			playback.track_changed.connect(_on_playback_track_changed)
			_set_playback_track(playback.track)
		else:
			_set_playback_track(null)

func set_scroll(value : float) -> void:
	value = clampf(value, 0, get_scroll_max())
	if scroll != value:
		var scroll_progress_befor : float = get_scroll_progress()
		scroll = value
		scroll_changed.emit(scroll)
		var scroll_progress_after : float = get_scroll_progress()
		if scroll_progress_befor != scroll_progress_after:
			scroll_progress_changed.emit(scroll_progress_after)
	queue_redraw()

func set_scroll_progress(value : float) -> void:
	value = clampf(value, 0, 1)
	scroll = value * get_scroll_max()

func set_selected_tracks(tracks : Array[DBTrack]) -> void:
	if tracks != _selected_tracks:
		_selected_tracks = tracks.duplicate()
		selected_tracks_changed.emit()
		queue_redraw()

func get_scroll_progress() -> float:
	return clampf(scroll / get_scroll_max(), 0, 1)

func _set_playback_track(value : DBTrack) -> void:
	if value != _playback_track:
		var track_index_before : int = -1
		if _playback_track and db_list:
			track_index_before = db_list.get_tracks().find(_playback_track)
		
		var track_index_after : int = -1
		if value:
			track_index_after = db_list.get_tracks().find(value)
		
		_playback_track = value
		
		var line_max_count : int = ceili(get_page_size())
		var begin : int = floori(scroll)
		var end : int = begin + line_max_count
		var visible_befor : bool = track_index_before >= begin and track_index_before < end
		var visible_after : bool = track_index_after >= begin and track_index_after < end
		
		if visible_befor or visible_after:
			queue_redraw()
		
		## был ли один из треков в списке db_list
		if track_index_before >= 0 or track_index_after >= 0:
			if visible_befor:
				var margin : int = 2
				margin = clampi(margin, 0, floori(line_max_count / 2.0))
				## если проигрываемый трек сдвинулся на 1 строку, то скроллим за ним.
				var track_line_change := track_index_after - track_index_before
				if absi(track_line_change) == 1:
					var track_line_index_before := track_index_before - begin
					if track_line_change > 0:
						if track_line_index_before >= margin:
							scroll += track_line_change
					elif track_line_change < 0:
						if track_line_index_before <= line_max_count - 1 - margin:
							scroll += track_line_change

func get_page_size() -> float:
	var size_y : float = size.y
	var track_interval : float = _track_drawer.interval
	return maxf(0, size_y / track_interval)

func get_scroll_max() -> float:
	var tracks_count : int
	if db_list:
		tracks_count = db_list.get_tracks().size()
	var page_size : float = get_page_size()
	return maxf(0, tracks_count - page_size)

func get_track_at_position(at_position : Vector2) -> DBTrack:
	for rect : Rect2 in _rect_to_track:
		if rect.has_point(at_position):
			return _rect_to_track[rect]
	return null

func get_selected_tracks(cleared : bool = true) -> Array[DBTrack]:
	if cleared:
		if db_list:
			var list : Array[DBTrack] = db_list.get_tracks()
			var selected_tracks : Array[DBTrack]
			for track in _selected_tracks:
				if track in list:
					selected_tracks.append(track)
			return selected_tracks
		else:
			return [] as Array[DBTrack]
	return _selected_tracks.duplicate()

func _theme_changed() -> void:
	_track_drawer_updated = false
	if theme_type_variation:
		_track_drawer.theme_type = theme_type_variation
	else:
		_track_drawer.theme_type = THEME_TYPE
	queue_redraw()

func _on_db_list_changed() -> void:
	_selection_begin_update()
	queue_redraw()

func _on_playback_track_changed(track : DBTrack) -> void:
	_set_playback_track(track)

func _selection_begin_update() -> void:
	if _selection:
		var selected_tracks : Array[DBTrack] = _selection_tracks.duplicate()
		if db_list:
			var selection_from : int = mini(_selection_from, _selection_to)
			var selection_to : int = maxi(_selection_from, _selection_to) + 1
			var selection_tracks : Array[DBTrack] = db_list.get_tracks().slice(selection_from, selection_to)
			for track : DBTrack in selection_tracks:
				if track not in selected_tracks:
					selected_tracks.append(track)
				else:
					selected_tracks.erase(track)
		set_selected_tracks(selected_tracks)
