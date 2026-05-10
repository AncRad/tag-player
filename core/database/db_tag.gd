extends DBItem
class_name DBTag

signal track_list_changed

var roles : Array[StringName]
var names : Array[StringName]
var _track_to_role : Dictionary[DBTrack, StringName]


func _to_string() -> String:
	if names:
		return names[0]
	return 'UnnamedTag'

func tag(track : DBTrack, role : StringName) -> void:
	assert(track)
	
	if self in track._tag_to_role:
		untag(track)
	
	_track_to_role[track] = role
	
	# FIXME переместить в DBTrack
	track._tag_to_role[self] = role
	if not role in track._role_to_tags:
		track._role_to_tags[role] = [] as Array[DBTag]
	track._role_to_tags[role].append(self)
	track.order_string = track.generate_order_string()
	track.changes_up()
	
	changes_up()
	track_list_changed.emit()
	
	# FIXME переместить в DBTrack
	track.tag_list_changed.emit()

func untag(track : DBTrack) -> void:
	assert(track)
	assert(self in track._tag_to_role)
	assert(track in _track_to_role)
	
	var role : StringName = track._tag_to_role[self]
	
	_track_to_role.erase(track)
	
	# FIXME переместить в DBTrack
	track._role_to_tags[role].erase(self)
	if not track._role_to_tags[role]:
		track._role_to_tags.erase(role)
	track._tag_to_role.erase(self)
	track.order_string = track.generate_order_string()
	track.changes_up()
	
	changes_up()
	track_list_changed.emit()
	
	# FIXME переместить в DBTrack
	track.tag_list_changed.emit()

func get_track_to_role() -> Dictionary[DBTrack, StringName]:
	return _track_to_role.duplicate()

func get_first_name(default : String = 'UnnamedTag') -> String:
	if names and names[0]:
		return names[0]
	else:
		return default
