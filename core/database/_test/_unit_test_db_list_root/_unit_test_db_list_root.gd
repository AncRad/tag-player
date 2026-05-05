extends Node

## Юнит-тест для DBListRoot, DBTrack, DBTag.
## Запустить сцену _unit_test_db_list_root.tscn — результаты будут выведены в Output.

var _pass_count : int = 0
var _fail_count : int = 0
var _current_test : String = ''


func _ready() -> void:
	_run_test('add_track', _test_add_track)
	_run_test('add_tag', _test_add_tag)
	_run_test('add_track_and_tag_independently', _test_add_track_and_tag_independently)
	_run_test('tag_creates_records', _test_tag_creates_records)
	_run_test('tag_updates_order_string', _test_tag_updates_order_string)
	_run_test('untag_removes_records', _test_untag_removes_records)
	_run_test('untag_removes_empty_role', _test_untag_removes_empty_role)
	_run_test('untag_keeps_other_tags_in_role', _test_untag_keeps_other_tags_in_role)
	_run_test('retag_changes_role', _test_retag_changes_role)
	_run_test('retag_no_duplicate_in_track_to_role', _test_retag_no_duplicate_in_track_to_role)
	_run_test('add_track_changes_up', _test_add_track_changes_up)
	_run_test('tag_propagates_changes_up', _test_tag_propagates_changes_up)
	_print_summary()


# ─────────────────────────────────────────────────────────────────────────────
# Вспомогательные методы
# ─────────────────────────────────────────────────────────────────────────────

func _run_test(test_name : String, callable : Callable) -> void:
	_current_test = test_name
	print('\n=== ', test_name, ' ===')
	callable.call()

func _expect(condition : bool, message : String) -> void:
	if condition:
		_pass_count += 1
		print('  [PASS]  ', message)
	else:
		_fail_count += 1
		print('  [FAIL]  ', message, '  <-- ', _current_test)

func _print_summary() -> void:
	print('\n', '─'.repeat(50))
	var total := _pass_count + _fail_count
	print('Итого: %d/%d прошло' % [_pass_count, total])
	if _fail_count == 0:
		print('Все тесты прошли успешно.')
	else:
		print('ПРОВАЛЕНО: ', _fail_count)
	print('─'.repeat(50))

func _make_root() -> DBListRoot:
	return DBListRoot.new()

func _make_track(root : DBListRoot, file_path : StringName = &'test.mp3') -> DBTrack:
	var track := DBTrack.new()
	track.file_path = file_path
	root.add_item(track)
	return track

func _make_tag(root : DBListRoot, tag_name : StringName = &'test_tag') -> DBTag:
	var tag := DBTag.new()
	tag.names = [tag_name]
	root.add_item(tag)
	return tag


# ─────────────────────────────────────────────────────────────────────────────
# Тест 1: add_item(DBTrack) — создаёт нужные записи
# ─────────────────────────────────────────────────────────────────────────────

func _test_add_track() -> void:
	var root := _make_root()
	var track := DBTrack.new()
	track.file_path = &'song.mp3'
	
	# Сигналы
	var sig_item : Array[DBItem] = []
	var sig_track : Array[DBTrack] = []
	var sig_tag : Array[DBTrack] = []
	root.added_item.connect(func(i : DBItem): sig_item.append(i))
	root.added_track.connect(func(t : DBTrack): sig_track.append(t))
	root.added_tag.connect(func(t : DBTrack): sig_tag.append(t))
	var sig_list_changed : Array
	root.list_changed.connect(func(): sig_list_changed.append(null))
	
	root.add_item(track)
	root.update()
	
	# Приватные поля
	_expect(track in root._items, '_items содержит track')
	_expect(track in root._tracks, '_tracks содержит track')
	_expect(track not in root._tags, '_tags НЕ содержит track')
	
	# Обратная ссылка
	_expect(track._root == root, 'track._root указывает на root')
	
	# Публичный API
	_expect(track in root.get_tracks(), 'get_tracks() возвращает track')
	_expect(track not in ([] + root._tags), 'track НЕ попал в _tags')
	_expect(root.get_tags().is_empty(),
		'get_tags() пуст — в root добавлен только track')
	
	# Сигналы
	_expect(sig_item.size() == 1 and sig_item[0] == track, 'сигнал added_item(track) получен ровно 1 раз')
	_expect(sig_track.size() == 1 and sig_track[0] == track, 'сигнал added_track(track) получен ровно 1 раз')
	_expect(sig_list_changed.size() == 1, 'сигнал sig_list_changed получен ровно 1 раз')
	_expect(sig_tag.size() == 0, 'сигнал added_tag получен ровно 0 раз')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 2: add_item(DBTag) — создаёт нужные записи
# ─────────────────────────────────────────────────────────────────────────────

func _test_add_tag() -> void:
	var root := _make_root()
	var tag := DBTag.new()
	tag.names = [&'rock']
	
	# Сигналы
	var sig_item : Array[DBItem] = []
	var sig_tag : Array[DBTag] = []
	root.added_item.connect(func(i : DBItem): sig_item.append(i))
	root.added_tag.connect(func(t : DBTag): sig_tag.append(t))
	var sig_list_changed : Array
	root.list_changed.connect(func(): sig_list_changed.append(null))
	
	root.add_item(tag)
	root.update()
	
	# Приватные поля
	_expect(tag in root._items, '_items содержит tag')
	_expect(tag in root._tags, '_tags содержит tag')
	_expect(tag not in root._tracks, '_tracks НЕ содержит tag')
	
	# Обратная ссылка
	_expect(tag._root == root, 'tag._root указывает на root')
	
	# Публичный API
	_expect(tag in root.get_tags(), 'get_tags() возвращает tag')
	_expect(root.get_tracks().is_empty(), 'get_tracks() пуст — в root добавлен только tag')
	
	# Сигналы
	_expect(sig_item.size() == 1 and sig_item[0] == tag,
		'сигнал added_item(tag) получен ровно 1 раз')
	_expect(sig_tag.size() == 1 and sig_tag[0] == tag,
		'сигнал added_tag(tag) получен ровно 1 раз')
	_expect(sig_list_changed.size() == 0, 'сигнал sig_list_changed получен ровно 0 раз')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 3: DBTrack и DBTag добавляются независимо, не попадая в чужие списки
# ─────────────────────────────────────────────────────────────────────────────

func _test_add_track_and_tag_independently() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root)
	root.update()
	
	_expect(root._items.size() == 2, '_items содержит ровно 2 элемента')
	_expect(root._tracks.size() == 1, '_tracks содержит ровно 1 элемент')
	_expect(root._tags.size() == 1, '_tags содержит ровно 1 элемент')
	
	_expect(tag not in ([] + root._tracks), 'tag НЕ попал в _tracks')
	_expect(track not in ([] + root._tags), 'track НЕ попал в _tags')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 4: DBTag.tag(track, role) — создаёт все нужные записи
# ─────────────────────────────────────────────────────────────────────────────

func _test_tag_creates_records() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root, &'rock')
	
	# Сигналы — массив как изменяемый счётчик (лямбды захватывают по ссылке)
	var tag_list_changed := [0]
	var track_list_changed := [0]
	tag.track_list_changed.connect(func(): tag_list_changed[0] += 1)
	track.tag_list_changed.connect(func(): track_list_changed[0] += 1)
	var sig_list_changed : Array
	root.list_changed.connect(func(): sig_list_changed.append(null))
	
	tag.tag(track, &'genre')
	root.update()
	
	# DBTag → DBTrack
	_expect(track in tag._track_to_role,
		'tag._track_to_role содержит track')
	_expect(tag._track_to_role[track] == &'genre',
		"tag._track_to_role[track] == 'genre'")
	
	# DBTrack → DBTag
	_expect(tag in track._tag_to_role,
		'track._tag_to_role содержит tag')
	_expect(track._tag_to_role[tag] == &'genre',
		"track._tag_to_role[tag] == 'genre'")
	
	# Роли
	_expect(&'genre' in track._role_to_tags,
		"track._role_to_tags содержит ключ 'genre'")
	_expect(tag in track._role_to_tags[&'genre'],
		"track._role_to_tags['genre'] содержит tag")
	_expect(track._role_to_tags[&'genre'].size() == 1,
		"track._role_to_tags['genre'] содержит ровно 1 тег")

	# Сигналы
	_expect(tag_list_changed[0] == 1,
		'сигнал tag.track_list_changed получен ровно 1 раз')
	_expect(track_list_changed[0] == 1,
		'сигнал track.tag_list_changed получен ровно 1 раз')
	_expect(sig_list_changed.size() == 0, 'сигнал sig_list_changed получен ровно 0 раз')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 5: tag() обновляет order_string
# ─────────────────────────────────────────────────────────────────────────────

func _test_tag_updates_order_string() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root, &'Artist Name')
	
	var order_before := track.order_string
	tag.tag(track, &'creator')
	root.update()
	var order_after := track.order_string
	
	_expect(order_after != order_before or order_after != '',
		'order_string изменился после tag() с ролью creator')
	_expect('Artist Name' in order_after,
		"order_string содержит имя creator 'Artist Name'")


# ─────────────────────────────────────────────────────────────────────────────
# Тест 6: DBTag.untag(track) — удаляет все нужные записи
# ─────────────────────────────────────────────────────────────────────────────

func _test_untag_removes_records() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root, &'rock')
	
	tag.tag(track, &'genre')
	
	# Сигналы после untag
	var tag_list_changed := [0]
	var track_list_changed := [0]
	tag.track_list_changed.connect(func(): tag_list_changed[0] += 1)
	track.tag_list_changed.connect(func(): track_list_changed[0] += 1)
	var sig_list_changed : Array
	root.list_changed.connect(func(): sig_list_changed.append(null))
	
	tag.untag(track)
	root.update()
	
	# DBTag → DBTrack
	_expect(track not in tag._track_to_role,
		'tag._track_to_role НЕ содержит track')
	
	# DBTrack → DBTag
	_expect(tag not in track._tag_to_role,
		'track._tag_to_role НЕ содержит tag')
	
	# Роли
	_expect(&'genre' not in track._role_to_tags,
		"track._role_to_tags НЕ содержит ключ 'genre' (массив был пустым — ключ удалён)")
	
	# Сигналы
	_expect(tag_list_changed[0] == 1,
		'сигнал tag.track_list_changed получен ровно 1 раз')
	_expect(track_list_changed[0] == 1,
		'сигнал track.tag_list_changed получен ровно 1 раз')
	_expect(sig_list_changed.size() == 0, 'сигнал sig_list_changed получен ровно 0 раз')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 7: untag удаляет ключ роли если в массиве больше нет тегов
# ─────────────────────────────────────────────────────────────────────────────

func _test_untag_removes_empty_role() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root, &'rock')
	
	tag.tag(track, &'genre')
	tag.untag(track)
	root.update()
	
	_expect(track._role_to_tags.is_empty() or &'genre' not in track._role_to_tags,
		"ключ 'genre' удалён из _role_to_tags когда массив стал пустым")


# ─────────────────────────────────────────────────────────────────────────────
# Тест 8: untag оставляет другие теги в той же роли
# ─────────────────────────────────────────────────────────────────────────────

func _test_untag_keeps_other_tags_in_role() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag_a := _make_tag(root, &'TagA')
	var tag_b := _make_tag(root, &'TagB')
	
	tag_a.tag(track, &'genre')
	tag_b.tag(track, &'genre')
	
	tag_a.untag(track)
	root.update()
	
	_expect(&'genre' in track._role_to_tags,
		"ключ 'genre' остался в _role_to_tags после удаления одного из двух тегов")
	_expect(tag_b in track._role_to_tags[&'genre'],
		"tag_b остался в _role_to_tags['genre']")
	_expect(tag_a not in track._role_to_tags[&'genre'],
		"tag_a удалён из _role_to_tags['genre']")
	_expect(track._role_to_tags[&'genre'].size() == 1,
		"_role_to_tags['genre'] содержит ровно 1 тег")


# ─────────────────────────────────────────────────────────────────────────────
# Тест 9: повторный tag() с другой ролью меняет роль (retag)
# ─────────────────────────────────────────────────────────────────────────────

func _test_retag_changes_role() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root, &'rock')
	
	tag.tag(track, &'genre')
	tag.tag(track, &'style') # повторное тегирование — должен сменить роль
	root.update()
	
	_expect(&'genre' not in track._role_to_tags,
		"старая роль 'genre' удалена из _role_to_tags")
	_expect(&'style' in track._role_to_tags,
		"новая роль 'style' присутствует в _role_to_tags")
	_expect(tag in track._role_to_tags[&'style'],
		"_role_to_tags['style'] содержит tag")
	_expect(track._tag_to_role[tag] == &'style',
		"track._tag_to_role[tag] == 'style'")
	_expect(tag._track_to_role[track] == &'style',
		"tag._track_to_role[track] == 'style'")


# ─────────────────────────────────────────────────────────────────────────────
# Тест 10: retag — track встречается в tag._track_to_role ровно 1 раз
# ─────────────────────────────────────────────────────────────────────────────

func _test_retag_no_duplicate_in_track_to_role() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root)
	
	tag.tag(track, &'genre')
	tag.tag(track, &'style')
	root.update()
	
	var count := 0
	for t : DBTrack in tag._track_to_role:
		if t == track:
			count += 1
	
	_expect(count == 1,
		'track встречается в tag._track_to_role ровно 1 раз после retag')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 11: add_item() вызывает changes_up() на root
# ─────────────────────────────────────────────────────────────────────────────

func _test_add_track_changes_up() -> void:
	var root := _make_root()
	var changes := root._changes
	
	var track := DBTrack.new()
	root.add_item(track)
	root.update()
	
	_expect(root._changes > changes,
		'root._changes увеличился после add_item(track)')


# ─────────────────────────────────────────────────────────────────────────────
# Тест 12: tag() и untag() вызывают changes_up() на root
# ─────────────────────────────────────────────────────────────────────────────

func _test_tag_propagates_changes_up() -> void:
	var root := _make_root()
	var track := _make_track(root)
	var tag := _make_tag(root)
	
	var changes_before_tag := root._changes
	tag.tag(track, &'genre')
	root.update()
	_expect(root._changes > changes_before_tag,
		'root._changes увеличился после tag()')
	
	var changes_before_untag := root._changes
	tag.untag(track)
	root.update()
	_expect(root._changes > changes_before_untag,
		'root._changes увеличился после untag()')
