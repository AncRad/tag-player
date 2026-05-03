@abstract
extends Resource
class_name DBItem

var _root : DBListRoot


func is_valid() -> bool:
	return _root is DBListRoot

func changes_up() -> void:
	if _root:
		_root.changes_up()

func get_root() -> DBListRoot:
	return _root
