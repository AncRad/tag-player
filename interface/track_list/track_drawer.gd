extends RefCounted
class_name TrackDrawer

const SEPARATOR_STRING : String = ' - '
const DELIMITER_STRING : String = ', '
const TAG_MIN_STRING : String = 'MMM'
const BRACKET_STRING_BEGIN : String = ' ('
const BRACKET_STRING_END : String = ')'

# параметры темы
@export var theme_type : StringName = &''
@export var margin : int = 2
@export var font : Font = FontVariation.new()
@export var font_size : int = 14
@export var font_color : Color = Color.WHITE
@export var font_color_selected : Color = Color.WHITE
@export var separation : int = 20
@export var background_normal : StyleBox
@export var background_selected : StyleBox

# параметры для рисования
@export var font_height : float = 14
@export var interval : int = 14 + 2 + 2
#@export var font_ascent : int
@export var font_offset_y : int
#@export var max_count : int
@export var separator_length : float = 12
@export var delimieter_length : float = 8
@export var tag_length_min : float = 39
@export var bracket_length_begin : float = 5
@export var bracket_length_end : float = 5


func _init(p_theme_type : StringName = &'') -> void:
	theme_type = p_theme_type

func read_theme(context : Control) -> void:
	#var params_befor : Array[Variant]
	#for prop in (TrackDrawer as Script).get_script_property_list():
		#if prop.usage == PROPERTY_USAGE_DEFAULT:
			#params_befor.append(self[prop.name])
	
	# параметры темы
	margin = context.get_theme_constant(&'margin', theme_type)
	font = context.get_theme_font(&'track_font', theme_type)
	font_size = context.get_theme_font_size(&'track_font_size', theme_type)
	font_color = context.get_theme_color(&'track_font_color', theme_type)
	separation = context.get_theme_constant(&'track_separation', theme_type)
	background_normal = context.get_theme_stylebox(&'track_background_normal', theme_type)
	background_selected = context.get_theme_stylebox(&'track_background_selected', theme_type)
	
	# параметры для рисования
	font_height = font.get_height(font_size)
	interval = int(font_height + separation)
	#font_ascent = int(track_font.get_ascent(track_font_size))
	font_offset_y = int(font.get_ascent(font_size) + separation / 2.0)
	#max_count = maxi(0, ceili(size.y / track_interval + wrapf(scroll, 0, 1)))
	separator_length = font.get_string_size(SEPARATOR_STRING, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	delimieter_length = font.get_string_size(DELIMITER_STRING, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	tag_length_min = font.get_string_size(TAG_MIN_STRING, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	bracket_length_begin = font.get_string_size(BRACKET_STRING_BEGIN, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	bracket_length_end = font.get_string_size(BRACKET_STRING_END, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func draw_track(item : RID, track : DBTrack, rect : Rect2) -> void:
	# прямоугольная область пустого пространства трека, будет уменьшаться по мере рисования
	var rect_void : Rect2 = rect.grow_individual(-margin, 0, -margin, 0)
	
	var creators : Array[DBTag] = track.get_role_to_tags().get(&'creator', [] as Array[DBTag])
	var creators_max_length : float = (rect.size.x - margin * 2 - separator_length) / 3 * 2
	var creators_rect : Rect2 = rect_void
	creators_rect.size.x = creators_max_length
	creators_rect = draw_tags(item, creators, creators_rect)
	rect_void = rect_void.grow_side(SIDE_LEFT, -creators_rect.size.x)
	
	draw_string(item, SEPARATOR_STRING, rect_void)
	rect_void = rect_void.grow_side(SIDE_LEFT, -separator_length)
	
	var track_name_rect : Rect2 = draw_string(item, track.name, rect_void)
	rect_void = rect_void.grow_side(SIDE_LEFT, -track_name_rect.size.x)
	
	if rect_void.size.x >= bracket_length_begin + tag_length_min + bracket_length_end:
		var versions : Array[DBTag] = track.get_role_to_tags().get(&'version', [] as Array[DBTag])
		if versions:
			draw_string(item, BRACKET_STRING_BEGIN, rect_void)
			rect_void = rect_void.grow_side(SIDE_LEFT, -bracket_length_begin)
			var versions_rect : Rect2 = draw_tags(item, versions, rect_void)
			rect_void = rect_void.grow_side(SIDE_LEFT, -versions_rect.size.x)
			if rect_void.size.x >= bracket_length_end:
				draw_string(item, BRACKET_STRING_END, rect_void)
				rect_void = rect_void.grow_side(SIDE_LEFT, -bracket_length_end)

func draw_tags(item : RID, tags : Array[DBTag], rect : Rect2) -> Rect2:
	# прямоугольная область пустого пространства тегов, будет уменьшаться по мере рисования
	var rect_void : Rect2 = rect
	var first := true
	for tag in tags:
		if first:
			if rect_void.size.x < tag_length_min:
				break
		else:
			if rect_void.size.x < delimieter_length + tag_length_min:
				break
			
			draw_string(item, DELIMITER_STRING, rect_void)
			rect_void = rect_void.grow_side(SIDE_LEFT, -delimieter_length)
		
		var tag_rect : Rect2 = draw_string(item, tag.get_first_name(), rect_void)
		rect_void = rect_void.grow_side(SIDE_LEFT, -tag_rect.size.x)
		
		first = false
	
	var tags_rect : Rect2 = rect
	tags_rect = tags_rect.grow_side(SIDE_LEFT, -rect_void.size.x)
	
	assert(tags_rect.size.x <= rect.size.x + 5)
	
	tags_rect.size.x = min(tags_rect.size.x, rect.size.x)
	
	return tags_rect

func draw_string(item : RID, string : String, rect : Rect2) -> Rect2:
	font.draw_string(item, rect.position + Vector2(0, font_offset_y), string, HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x, font_size, font_color, TextServer.JUSTIFICATION_NONE)
	
	var string_rect : Rect2 = rect
	string_rect.size.x = font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x, font_size, TextServer.JUSTIFICATION_NONE).x
	
	assert(string_rect.size.x <= rect.size.x + 5)
	
	string_rect.size.x = min(string_rect.size.x, rect.size.x)
	
	return string_rect
