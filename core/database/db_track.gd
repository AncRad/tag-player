extends DBItem
class_name DBTrack

@warning_ignore('unused_signal')
signal tags_changed

@export var file_path : StringName
@export var name : StringName

var order_string : String

var _tag_to_role : Dictionary[DBTag, StringName]
var _role_to_tags : Dictionary[StringName, Array] # : Dictionary[StringName, Array[DBTag]]


func get_tag_to_role() -> Dictionary[DBTag, StringName]:
	return _tag_to_role.duplicate()

## -> Dictionary[StringName, Array[DBTag]]
func get_role_to_tags() -> Dictionary[StringName, Array]:
	return _role_to_tags.duplicate()

func generate_order_string() -> String:
	var creators_names : Array[StringName]
	var creators : Array[DBTag] = get_role_to_tags().get('creator', [] as Array[DBTag])
	for creator : DBTag in creators:
		for creator_name : StringName in creator.names:
			if creator_name:
				creators_names.append(creator_name)
				break
	
	if creators_names:
		return str(', '.join(creators_names), ' - ', name)
	else:
		return file_path.get_file().get_basename()
