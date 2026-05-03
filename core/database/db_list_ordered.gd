extends DBListNode
class_name DBListOrdered

@export var inverted : bool:
	set(value):
		if value != inverted:
			inverted = value
			changes_up()


func get_ordered() -> DBListOrdered:
	return self

## Возвращает родительский неупорядоченный узел (не унаследованный от [DBListOrdered]),
## если такого нет, то возвращает [param default],
## по умолчанию [param default] == [code]self[/code].
func get_not_ordered(default : DBListNode = self) -> DBListNode:
	if parent:
		var not_ordered : DBListNode = parent.get_not_ordered(default)
		if not_ordered is DBListOrdered:
			return default
		return not_ordered
	return default

func get_tracks() -> Array[DBTrack]:
	return _tracks.duplicate()

func _update() -> void:
	var tracks : Array[DBTrack]
	if parent:
		tracks = parent.get_tracks()
	
	var order_string_to_track : Dictionary[String, DBTrack]
	for track : DBTrack in tracks:
		if track.order_string in order_string_to_track:
			order_string_to_track[str(track.order_string, track.get_instance_id())] = track
		else:
			order_string_to_track[track.order_string] = track
	
	order_string_to_track.sort()
	
	tracks.assign(order_string_to_track.values())
	if inverted:
		tracks.reverse()
	
	if _tracks != tracks:
		_tracks = tracks
		changes_up()
