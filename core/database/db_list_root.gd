@tool
extends DBListNode
class_name DBListRoot

signal added_item(item : DBItem)
signal added_tag(tag : DBTag)
signal added_track(track : DBTrack)
signal removed_item(item : DBItem)
signal removed_tag(tag : DBTag)
signal removed_track(track : DBTrack)

var _items : Array[DBItem]
var _tags : Array[DBTag]


func _init() -> void:
	pass

func _validate_property(property : Dictionary) -> void:
	if property.name == &'parent':
		property.usage = PROPERTY_USAGE_NONE

func set_parent(_parent) -> void:
	if _parent != null:
		assert(false, 'DBListRoot cannot have a parent')

func _update() -> void:
	pass

func add_item(item : DBItem) -> void:
	assert(item)
	assert(not item._root)
	assert(item not in _items)
	assert(item is not DBTag or item not in _tags)
	assert(item is not DBTrack or item not in _tracks)
	
	if item is DBTag:
		_items.append(item)
		_tags.append(item)
		item._root = self
		added_item.emit(item)
		added_tag.emit(item)
	
	elif item is DBTrack:
		_items.append(item)
		_tracks.append(item)
		item._root = self
		added_item.emit(item)
		added_track.emit(item)
		list_changed.emit()
	
	else:
		_items.append(item)
		item._root = self
		added_item.emit(item)
	
	changes_up()

func remove_item(item : DBItem) -> void:
	assert(item)
	assert(item._root == self)
	assert(item in _items)
	assert(item is not DBTag or item in _tags)
	assert(item is not DBTrack or item in _tracks)
	
	if item is DBTag:
		_items.erase(item)
		_tags.erase(item)
		item._root = null
		removed_item.emit(item)
		removed_tag.emit(item)
	
	elif item is DBTrack:
		_items.erase(item)
		_tracks.erase(item)
		item._root = null
		removed_item.emit(item)
		removed_track.emit(item)
		list_changed.emit()
	
	else:
		_items.erase(item)
		item._root = null
		removed_item.emit(item)
	
	changes_up()

func get_tags() -> Array[DBTag]:
	return _tags.duplicate()

func get_tracks() -> Array[DBTrack]:
	return _tracks.duplicate()

func find_tags_by_name(name : StringName, p_match := true, no_register := true, sort := true) -> Array[DBTag]:
	var tags : Array[DBTag] = []
	
	if no_register:
		name = name.to_lower()
	
	var filter := ''
	if p_match:
		var split := name.split(' ', false)
		if split:
			filter = '*%s*' % '*'.join(split)
	
	if not name or p_match and not filter:
		return []
	
	for tag in _tags:
		for tag_name in tag.names:
			var condition := false
			if p_match:
				if no_register:
					condition = tag_name.matchn(filter)
				else:
					condition = tag_name.match(filter)
			
			else:
				if no_register:
					condition = tag_name.to_lower().begins_with(name)
				else:
					condition = tag_name.begins_with(name)
			
			if condition:
				tags.append(tag)
				break
	
	if sort:
		var cache := {}
		var begin := [] as Array[DBTag]
		var end := [] as Array[DBTag]
		for tag in tags:
			var max_similarity := -INF
			var begins_with_name := false
			for tag_name in tag.names:
				if no_register:
					begins_with_name = tag_name.to_lower().begins_with(name)
				else:
					begins_with_name = tag_name.begins_with(name)
				if begins_with_name:
					cache[tag] = String(tag_name)
					begins_with_name = true
					begin.append(tag)
					break
				
				var similarity := tag_name.similarity(name)
				if similarity > max_similarity:
					max_similarity = similarity
					cache[tag] = String(tag_name)
			if not begins_with_name:
				end.append(tag)
		
		begin.sort_custom(func (a, b): return cache[a] < cache[b])
		end.sort_custom(func (a, b): return cache[a] < cache[b])
		tags = begin + end
	
	return tags

## FIXME:
## Ищет только по первому имени.
## Если тег имеет несколько имён и передаётся альтернативное имя — он не будет найден и создастся дубликат.
## При частичном поиске (p_match=true по умолчанию) это ещё и может найти другой тег по подстроке вместо точного совпадения.
## Стоит искать exact match.
func get_tag_or_create(names : Array[StringName], roles : Array[StringName] = []) -> DBTag:
	if names:
		var tags := find_tags_by_name(names[0])
		if tags:
			return tags[0]
		else:
			var tag : DBTag = DBTag.new()
			tag.names = names
			tag.roles = roles
			add_item(tag)
			return tag
	return null
