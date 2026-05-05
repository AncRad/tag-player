extends Resource
class_name DBTrackComparatorNode

enum CompareMode {
	And,
	Or,
}

@export var compare_mode : CompareMode = CompareMode.And:
	set(value):
		assert(value in CompareMode)
		if value != compare_mode:
			compare_mode = value
			emit_changed()

@export var tags : Array[DBTag]:
	set(value):
		tags = value
		for tag in tags:
			if not tag.changed.is_connected(_on_tag_changed):
				tag.changed.connect(_on_tag_changed.bind(weakref(tag)))
		emit_changed()

@export var phrases : Array[String]:
	set(value):
		phrases = value
		_match_phrases.clear()
		for phrase : String in phrases:
			var words : Array[String]
			for word in phrase.split(' ', false):
				word = word.strip_edges()
				if word:
					words.append(str('*', word, '*'))
			if words:
				_match_phrases.append(words)
		emit_changed()

@export var filters : Array[DBTrackComparatorNode]:
	set(value):
		filters = value
		for filter in filters:
			if not filter.changed.is_connected(_on_filter_changed):
				filter.changed.connect(_on_filter_changed.bind(weakref(filter)))
		
		emit_changed()

@export var inverted : bool:
	set(value):
		if value != inverted:
			inverted = value
			emit_changed()

var _match_phrases : Array[Array] # : Array[Array[String]]


func compare(track : DBTrack) -> bool:
	match compare_mode:
		CompareMode.And:
			if tags:
				if not tags.all(func (tag : DBTag): return tag in track._tag_to_role):
					return false != inverted
			
			if _match_phrases:
				var all_phrase_matched_all_words : bool = _match_phrases.all(
						func (phrase : Array[String]):
								return phrase.all(
									func (word : String):
											# TODO заменить track.order_string на track.find_string
											return track.order_string.matchn(word)
								)
				)
				if not all_phrase_matched_all_words:
					return false != inverted
			
			if filters:
				if not filters.all(func (filter : DBTrackComparatorNode): return filter.compare(track)):
					return false != inverted
			
			return true != inverted
		
		CompareMode.Or:
			if tags:
				if tags.any(func (tag : DBTag): return tag in track._tag_to_role):
					return true != inverted
			
			if _match_phrases:
				var any_phrase_matched_all_words : bool = _match_phrases.any(
						func (phrase : Array[String]):
								return phrase.all(
									func (word : String):
											# TODO заменить track.order_string на track.find_string
											return track.order_string.matchn(word)
								)
				)
				if any_phrase_matched_all_words:
					return true != inverted
			
			if filters:
				if filters.any(func (filter : DBTrackComparatorNode): return filter.compare(track)):
					return true != inverted
			
			return false != inverted
	
	return false != inverted

func _on_tag_changed(weak : WeakRef) -> void:
	assert(weak)
	assert(weak.get_ref() is DBTag)
	
	var tag : DBTag = weak.get_ref()
	if tag in tags:
		emit_changed()
	
	else:
		tag.changed.disconnect(_on_tag_changed)

func _on_filter_changed(weak : WeakRef) -> void:
	assert(weak)
	assert(weak.get_ref() is DBTrackComparatorNode)
	
	var filter : DBTrackComparatorNode = weak.get_ref()
	if filter in filters:
		emit_changed()
	
	else:
		filter.changed.disconnect(_on_filter_changed)
