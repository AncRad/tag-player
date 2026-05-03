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

@export var words : Array[String]:
	set(value):
		words = value
		_match_strings.clear()
		for word : String in words:
			for sub_word in word.split(' ', false):
				sub_word = sub_word.strip_edges()
				if sub_word:
					_match_strings.append(str('*', sub_word, '*'))
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

var _match_strings : Array[String]


func compare(track : DBTrack) -> bool:
	match compare_mode:
		CompareMode.And:
			for tag in tags:
				if tag not in track._tag_to_role:	
					return false != inverted
			
			for match_string : String in _match_strings:
				if not track.order_string.matchn(match_string):
					return false != inverted
			
			for filter in filters:
				if not filter.compare(track):
					return false != inverted
			
			return true != inverted
		
		CompareMode.Or:
			for tag in tags:
				if tag in track._tag_to_role:
					return true != inverted
			
			for match_string : String in _match_strings:
				if track.order_string.matchn(match_string):
					return true != inverted
			
			for filter in filters:
				if filter.compare(track):
					return true != inverted
			
			return false != inverted
	
	return false != inverted

func _on_tag_changed(weak : WeakRef) -> void:
	assert(weak)
	assert(weak.get_ref() is DBTag)
	
	var tag : DBTag = weak.get_ref()
	if tag not in tags:
		tag.changed.disconnect(_on_tag_changed)
		return
	
	emit_changed()

func _on_filter_changed(weak : WeakRef) -> void:
	assert(weak)
	assert(weak.get_ref() is DBTrackComparatorNode)
	
	var filter : DBTrackComparatorNode = weak.get_ref()
	if filter not in filters:
		filter.changed.disconnect(_on_filter_changed)
		return
	
	emit_changed()
