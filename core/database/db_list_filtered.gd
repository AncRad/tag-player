extends DBListNode
class_name DBListFiltered

@export var filter : DBTrackComparatorNode:
	set = set_filter


func get_tracks() -> Array[DBTrack]:
	return _tracks.duplicate()

func set_filter(value : DBTrackComparatorNode) -> void:
	if value != filter:
		if filter:
			filter.changed.disconnect(changes_up)
		
		filter = value
		
		if value:
			value.changed.connect(changes_up)
		changes_up()

func _update() -> void:
	var tracks : Array[DBTrack]
	if parent:
		tracks = parent.get_tracks()
	
	if filter:
		tracks = tracks.filter(filter.compare)
	
	if _tracks != tracks:
		_tracks = tracks
		changes_up()
