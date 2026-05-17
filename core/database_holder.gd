extends Node
class_name DatabaseHolder

@export var root : DBListRoot
@export var onready_load : String = 'G:/_FROM_SSD_2/from_lin/Музыка/0 новая коллекция'
@export var onprocess_update : bool = true


func _ready() -> void:
	if onready_load and root:
		load_dir(onready_load)

func _process(_delta) -> void:
	if onprocess_update and root:
		root.update()

func load_dir(path : String) -> void:
	var tracks_files : Array[String]
	for file_name in DirAccess.get_files_at(path):
		if file_name.get_extension().to_lower() == 'mp3':
			tracks_files.append(str(path, '\\', file_name))
	
	var tag_last_drop : DBTag = root.get_tag_or_create(['last_drop'], ['system'])
	var tag_instrumental : DBTag = root.get_tag_or_create(['instrumental'], ['version'])
	var tag_ost : DBTag = root.get_tag_or_create(['ost'], ['version'])
	var tag_remix : DBTag = root.get_tag_or_create(['remix'], ['version'])
	
	for track : DBTrack in tag_last_drop._track_to_role:
		tag_last_drop.untag(track)
	
	for file_path in tracks_files:
		var file_name : String = file_path.get_file().get_basename()
		# избавиться от точек
		file_name = file_name.replace('.', ' ')
		# избавиться от двойных пробелов
		while '  ' in file_name:
			file_name = file_name.replacen('  ', ' ')
		# избавиться от пробелов в начале и конце
		file_name = file_name.strip_edges()
		
		var track : DBTrack = DBTrack.new()
		track.file_path = file_path
		root.add_item(track)
		
		var file_name_parts : PackedStringArray = file_name.split(' - ', false)
		if file_name_parts.size() < 2:
			file_name_parts = file_name.split('-', false)
		if file_name_parts.size() > 1:
			
			# TODO обнаружить метки cover, video, live, remix, edit, IA, ost, etc
			
			# обнаружить имена создателей в левой части имени файла
			if true:
				# избавиться от точек
				var file_name_creators : String = file_name_parts[0]
				# определить разделители авторов
				var marks_to_replace : Array[String] = [
					'feat', 'ft',
					'mix', 'mix by', 'mixBy',
					'Remix', 'remix by', 'remixBy',
					'Re mix', 're mix by',
					'Remux', 'remux by', 'remuxBy',
					'Re mux', 're mux by',
					'mastering', 'masteringby', 'mastering by',
				]
				# заменить разделители авторов на запятые
				for mark : String in marks_to_replace:
					file_name_creators = file_name_creators.replacen(mark, ',')
				# связать теги авторов с треком
				for creator_name in file_name_creators.split(',', false):
					creator_name = creator_name.strip_edges()
					if creator_name:
						var creator_tag : DBTag = root.get_tag_or_create([creator_name], ['creator'])
						
						creator_tag.resource_name = creator_name # TEST DELETE
						
						creator_tag.tag(track, 'creator')
			
			var file_name_title : String = file_name_parts[1]
			
			# обнаружить метку инструментальной версии в правой части имени файла
			if true:
				# определить метки инструментальной версии
				var instrumental_marks : Array[String] = [
					'instrumental',
					'no choirs', 'noChoirs',
					'no choir', 'noChoir',
					'no vocals', 'noVocals',
					'no vocal', 'noVocal',
				]
				# определить, есть ли метка инструментальной версии
				var has_instrumental_mark : bool
				for instrumental_mark : String in instrumental_marks:
					if file_name_title.containsn(instrumental_mark):
						has_instrumental_mark = true
						# избавиться от метки инструментальной версии
						file_name_title = file_name_title.replacen(str('(', instrumental_mark, ')'), ' ')
						file_name_title = file_name_title.replacen(instrumental_mark, ' ')
				# избавиться от двойных пробелов
				while '  ' in file_name_title:
					file_name_title = file_name_title.replacen('  ', ' ')
				# связать метку инструментальной версии с треком
				if has_instrumental_mark:
					tag_instrumental.tag(track, 'version')
				# избавиться от пробелов в начале и конце названия трека
				file_name_title = file_name_title.strip_edges()
			
			# обнаружить метку OST в правой части имени файла
			if file_name_title.containsn('ost'):
				tag_ost.tag(track, 'version')
			
			# обнаружить метку remix в правой части имени файла
			if true:
				var remix_marks : Array[String] = [
					'Remix', 'remix by', 'remixBy',
					'Re mix', 're mix by',
					'Remux', 'remux by', 'remuxBy',
					'Re mux', 're mux by',
				]
				for remix_mark : String in remix_marks:
					if file_name_title.containsn(remix_mark):
						tag_remix.tag(track, 'version')
						break
			
			# TODO обнаружить имена создателей в правой части имени файла
			if true:
				pass
			
			# определить название трека, если обнаружились имена создателей
			if &'creator' in track._role_to_tags:
				track.name = file_name_title.strip_edges()
		
		track.order_string = track.generate_order_string()
