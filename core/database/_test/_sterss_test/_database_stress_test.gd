extends DatabaseHolder

# для удержания в памяти DBListNode
var lists : Array[DBListNode]


func _ready() -> void:
	if onready_load and root:
		load_dir(onready_load)
	
	build_tree()

func _process(_delta) -> void:
	if onprocess_update and root:
		var time := Time.get_ticks_usec()
		
		root.update()
		
		if Time.get_ticks_usec() - time > 1000:
			print('root.update() time: ', (Time.get_ticks_usec() - time))

func build_tree() -> void:
	# построить дерево простых DBListNode
	for i in 3:
		var i_list : DBListNode = DBListNode.new(root)
		lists.append(i_list)
		for j in 3:
			var j_list : DBListNode = DBListNode.new(i_list)
			lists.append(j_list)
			for k in 3:
				var k_list : DBListNode = DBListNode.new(j_list)
				lists.append(k_list)
	
	# дополнить дерево DBListOredered для каждого DBListNode
	for list in lists.duplicate():
		lists.append(list.get_ordered())

func _on_changes_timer_timeout() -> void:
	var time := Time.get_ticks_usec()
	
	for i in 50:
		var track : DBTrack = root.get_tracks().pick_random()
		var tag : DBTag = root.get_tags().pick_random()
		
		tag.tag(track, 'creator')
	
	print('внесение изменений time: ', (Time.get_ticks_usec() - time))

func _on_build_tree_timer_timeout() -> void:
	lists.clear()
	
	var time := Time.get_ticks_usec()
	
	build_tree()
	
	print('перестроение дерева time: ', (Time.get_ticks_usec() - time))
