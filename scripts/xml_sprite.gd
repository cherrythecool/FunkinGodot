@tool
class_name XMLSprite extends AnimatedSprite


class AnimationData extends RefCounted:
	var prefix:String
	var xml:String
	var fps:int
	var loop:bool
	var offset:Vector2
	func _init(_prefix:String,_xml:String,_fps:int,_loop:bool,_offset:Vector2) -> void:
		self.prefix = _prefix
		self.xml = _xml
		self.fps = _fps
		self.loop = _loop
		self.offset = _offset

@export_file('*.xml', '*.png') var xml_path:String:
	set(v):
		xml_path = v
		if Engine.is_editor_hint():
			load_from_file(xml_path)
var atlas_tex:Texture2D
var atlas_xml:PackedByteArray
var prefixes:Array[AnimationData]
func add_anim_prefix(anim:String,xml_anim:String, _offset:Vector2 = Vector2.ZERO, fps:int = 24,loop:bool = false):
	var anim_list = sprite_frames.get_animation_names()
	for i in anim_list:
		if i.to_lower().begins_with(xml_anim):
			xml_anim = i
			break
	var anim_data:AnimationData = AnimationData.new(anim,xml_anim,fps,loop,_offset)
	prefixes.append(anim_data)

func play_anim(anim:String):
	for i in prefixes:
		if i.prefix == anim:
				sprite_frames.set_animation_speed(i.xml,i.fps)
				play(i.xml)
				offset = i.offset


func load_from_file(path:String):
	var xml_p:String
	var img_p:String
	if path.ends_with(".png"):
		xml_p = "%s.xml" % path.get_basename()
		img_p = path
	else:
		xml_p = path
		img_p = path.get_basename() + ".png"
	atlas_tex = load(img_p)
	atlas_xml = FileAccess.get_file_as_bytes(xml_p)
	xml_path = xml_p
	parse()

func parse() -> void:
	if !is_instance_valid(atlas_tex):
		printerr("INVALID TEXTURE\n")
		return
	var parser:XMLParser = XMLParser.new()
	parser.open_buffer(atlas_xml)
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")

	while parser.read() == OK:
		var nodetype = parser.get_node_type()
		if nodetype == XMLParser.NODE_ELEMENT:
			var node = parser.get_node_name().to_lower()
			if node == "subtexture":
				var raw_name = parser.get_attribute_value(0)
				var tname = raw_name.substr(0,raw_name.length() - 4)
				var frame_number = raw_name.replace(tname,"").to_int()
				var pos = Vector2i(parser.get_named_attribute_value("x").to_int(),parser.get_named_attribute_value("y").to_int())
				var size = Vector2i(parser.get_named_attribute_value("width").to_int(),parser.get_named_attribute_value("height").to_int())

				## atlas texture stuff
				if !sprite_frames.has_animation(tname):
					sprite_frames.add_animation(tname)

				var tex:AtlasTexture = AtlasTexture.new()

				var xml_x = parser.get_named_attribute_value_safe("x").to_int()
				var xml_y = parser.get_named_attribute_value_safe("y").to_int()
				var xml_width = parser.get_named_attribute_value_safe("width").to_int()
				var xml_height = parser.get_named_attribute_value_safe("height").to_int()


				var xml_frame_height = parser.get_named_attribute_value_safe("frameHeight").to_int()
				var xml_frame_width = parser.get_named_attribute_value_safe("frameWidth").to_int()
				var xml_frame_x = parser.get_named_attribute_value_safe("frameX").to_int()
				var xml_frame_y = parser.get_named_attribute_value_safe("frameY").to_int()
				tex.atlas = atlas_tex
				tex.region = Rect2i(xml_x,xml_y,xml_width,xml_height)
				var has_frame_offset:bool = parser.has_attribute("frameWidth")
				if has_frame_offset:
					tex.margin = Rect2(-xml_frame_x,-xml_frame_y,
							xml_frame_width - xml_width,xml_frame_height - xml_height
					)
					tex.margin.size = tex.margin.size.max(abs(tex.margin.position))



				sprite_frames.add_frame(tname,tex)
				sprite_frames.set_animation_speed(tname,24)
				sprite_frames.set_animation_loop(tname,false)
