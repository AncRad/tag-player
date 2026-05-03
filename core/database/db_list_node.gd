extends Resource
class_name DBListNode

signal list_changed

enum UpdateMode {
	Always,
	Inherit,
	Never,
}

@export var parent : DBListNode:
	set = set_parent
@export var update_mode : UpdateMode = UpdateMode.Inherit

## Список дочерних [DBListNode] - не удерживает в памяти (слабые ссылки).
var _children : Array[DBListNode]
var _changes : int
var _changes_updated : int
var _changes_parent_cached : int
## Ссылка на упорядоченный DBListNode в виде DBListOrdered - не удерживает в памяти (слабая ссылка).
var _ordered : DBListOrdered


func _init(_parent : DBListNode = null) -> void:
	parent = _parent

func _notification(what : int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			# важно чтобы освобождение self не приводило к освобождению DBListNode из-за слабых ссылок.
			for child in _children:
				if is_instance_valid(child):
					child.reference()
			if is_instance_valid(_ordered):
				_ordered.reference()
			# важно чтобы в parent не было не действительных ссылок в _children
			if parent:
				for i in range(parent._children.size() - 1, -1, -1):
					if not is_instance_valid(parent._children[i]):
						parent._children.remove_at(i)

## Указать источник списка треков для этого DBListNode.
## Это равносильно [code]parent.remove_child(self)[/code], если [param parent] не равен [code]null[/code]
## и [code]value.add_child(self)[/code], если [param value] не равен [code]null[/code].
# TODO нужно предотвратить возможность создания циклических ссылок.
func set_parent(value : DBListNode) -> void:
	if value != parent:
		if parent:
			if self in parent._children:
				parent.remove_child(self)
			else:
				parent = null
		
		if value:
			if self in value._children:
				parent = value
			else:
				value.add_child(self)
		
		changes_up()

func changes_up() -> void:
	_changes += 1

func update() -> void:
	var do_update := need_update() and can_update()
	var updated : bool
	
	if do_update:
		var _changes_befor_update : int = _changes
		_update()
		updated = _changes_befor_update != _changes
		_changes_updated = _changes
		_changes_parent_cached = parent._changes_updated if parent else -1
	
	for child in get_children():
		child.update()
	
	if updated:
		list_changed.emit()

func can_update() -> bool:
	match update_mode:
		UpdateMode.Always:
			return true
		
		UpdateMode.Inherit:
			return not parent or parent.can_update()
		
		UpdateMode.Never:
			return false
		
		_:
			assert(false)
			return false

func need_update() -> bool:
	if _changes != _changes_updated:
		return true
	
	elif parent:
		return _changes_parent_cached != parent._changes_updated
	
	else:
		return _changes_parent_cached != -1

## Указать источник списка треков для этого [param child].
## Это равносильно [code]child.set_parent(self)[/code].
# TODO нужно предотвратить возможность создания циклических ссылок.
func add_child(child : DBListNode) -> void:
	assert(child)
	assert(child not in _children)
	assert(not child.parent)
	
	_children.append(child)
	child.unreference()
	child.parent = self
	
	changes_up()

## Указать источник списка треков для этого [param child].
## Это равносильно [code]child.set_parent(null)[/code].
func remove_child(child : DBListNode) -> void:
	assert(child)
	assert(child in _children)
	assert(child.parent)
	
	child.reference()
	_children.erase(child)
	child.parent = null
	
	changes_up()

func get_children() -> Array[DBListNode]:
	return _children.duplicate()

func get_ordered() -> DBListOrdered:
	var _keep : DBListOrdered
	if not is_instance_valid(_ordered):
		_ordered = DBListOrdered.new()
		add_child(_ordered)
		# удержать слабую ссылку в этом методе
		_keep = _ordered
		_ordered.unreference()
	return _ordered

## Возвращает не упорядоченный узел (не унаследованный от [DBListOrdered]) - [code]self[/code],
## параметр [param _default] используется если узел не унаследован от [DBListOrdered].
func get_not_ordered(_default : DBListNode = self) -> DBListNode:
	return self

func get_tracks() -> Array[DBTrack]:
	if parent:
		return parent.get_tracks()
	return []

func _update() -> void:
	changes_up()
