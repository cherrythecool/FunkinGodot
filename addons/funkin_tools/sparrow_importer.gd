@tool
extends Node


const SPARROW_IMPORTER_SPRITESHEET: PackedScene = preload("uid://eiv8nrtiovmp")

@onready var open_dialog: FileDialog = %open_dialog
@onready var save_dialog: FileDialog = %save_dialog
@onready var save_pngs_dialog: FileDialog = %save_pngs_dialog
@onready var spritesheet_container: BoxContainer = %spritesheet_container

var import_framerate: float = 24.0
var import_looping: bool = false
var import_path_prefix: bool = false

var export_clear_automatically: bool = false
var export_filter_edges: bool = true
var export_merge_spritesheets: bool = false

var imported_list: Dictionary[String, SpriteFrames] = {}
var export_index: int = 0


func _on_import_spritesheets_pressed() -> void:
	if not open_dialog.current_dir.begins_with("res://"):
		open_dialog.current_dir = "res://"
	open_dialog.popup_centered()


func _on_export_to_pngs_pressed(recursive: bool = false) -> void:
	if not recursive:
		export_index = 0
	
	if imported_list.is_empty():
		return
	
	var key: String = imported_list.keys()[export_index]
	save_pngs_dialog.title = "Saving PNGs of %s" % [key.get_file(),]
	save_pngs_dialog.current_dir = key.get_base_dir()
	save_pngs_dialog.popup_centered()


func _on_save_pngs_dialog_dir_selected(dir: String) -> void:
	if export_merge_spritesheets:
		save_to_pngs(dir, parse_all_sparrows())
	else:
		save_to_pngs(dir, imported_list[imported_list.keys()[export_index]])
		
		export_index += 1
		if export_index <= imported_list.keys().size() - 1:
			_on_export_to_pngs_pressed(true)
		else:
			if export_clear_automatically:
				imported_list.clear()
				for child: Node in spritesheet_container.get_children():
					child.queue_free()


func _on_export_to_spriteframes_pressed(recursive: bool = false) -> void:
	if not recursive:
		export_index = 0
	
	if imported_list.is_empty():
		return
	
	var key: String = imported_list.keys()[export_index]
	save_dialog.title = "Saving SpriteFrames of %s" % [key.get_file(),]
	save_dialog.current_dir = key.get_base_dir()
	save_dialog.current_file = "%s.res" % [key.get_basename().get_file()]
	save_dialog.popup_centered()


func _on_save_dialog_file_selected(path: String) -> void:
	if export_merge_spritesheets:
		save_sprite_frames(path, parse_all_sparrows())
	else:
		save_sprite_frames(path, imported_list[imported_list.keys()[export_index]])
		
		export_index += 1
		if export_index <= imported_list.keys().size() - 1:
			_on_export_to_spriteframes_pressed(true)
		else:
			if export_clear_automatically:
				imported_list.clear()
				for child: Node in spritesheet_container.get_children():
					child.queue_free()


func _on_fps_box_value_changed(value: float) -> void:
	import_framerate = roundf(value)


func _on_looping_toggled(toggled_on: bool) -> void:
	import_looping = toggled_on


func _on_path_prefix_toggled(toggled_on: bool) -> void:
	import_path_prefix = toggled_on


func _on_clear_on_export_toggled(toggled_on: bool) -> void:
	export_clear_automatically = toggled_on


func _on_filter_clips_toggled(toggled_on: bool) -> void:
	export_filter_edges = toggled_on


func _on_merge_spritesheets_toggled(toggled_on: bool) -> void:
	export_merge_spritesheets = toggled_on


func get_path_prefix(path: String) -> String:
	return path.get_basename().get_file()


func _on_open_dialog_files_selected(paths: PackedStringArray) -> void:
	for path: String in paths:
		import_spritesheet(path)


func import_spritesheet(path: String) -> void:
	if imported_list.has(path):
		return
	
	var imported_frames: SpriteFrames = import_sparrow_atlas(path)
	if not is_instance_valid(imported_frames):
		return
	
	imported_list.set(path, imported_frames)
	
	var panel: PanelContainer = SPARROW_IMPORTER_SPRITESHEET.instantiate()
	var spritesheet_label: Label = panel.get_node(^"%spritesheet_label")
	spritesheet_label.text = path.replace("res://", "")
	
	var fps_box: SpinBox = panel.get_node(^"%fps_box")
	fps_box.value = import_framerate
	fps_box.value_changed.connect(func(value: float) -> void:
		for animation: String in imported_frames.get_animation_names():
			imported_frames.set_animation_speed(animation, value)
	)
	
	var looping_checkbox: CheckBox = panel.get_node(^"%looping_checkbox")
	looping_checkbox.button_pressed = import_looping
	looping_checkbox.toggled.connect(func(value: bool) -> void:
		for animation: String in imported_frames.get_animation_names():
			imported_frames.set_animation_loop(animation, value)
	)
	
	var path_prefix: CheckBox = panel.get_node(^"%path_prefix")
	path_prefix.button_pressed = import_path_prefix
	path_prefix.toggled.connect(func(value: bool) -> void:
		imported_frames.set_meta(&"path_prefix", value)
	)

	var remove_button: Button = panel.get_node(^"%remove_button")
	remove_button.pressed.connect(func() -> void:
		panel.queue_free()
		imported_list.erase(path)
	)
	
	spritesheet_container.add_child(panel)


func save_to_pngs(dir: String, sprite_frames: SpriteFrames) -> void:
	if not is_instance_valid(sprite_frames):
		return
	
	for animation: String in sprite_frames.get_animation_names():
		for index: int in sprite_frames.get_frame_count(animation):
			var texture: Texture2D = sprite_frames.get_frame_texture(animation, index)
			texture.get_image().save_png("%s/%s%04d.png" % [dir, animation, index])


func save_sprite_frames(path: String, sprite_frames: SpriteFrames) -> void:
	var import_options: Dictionary = save_dialog.get_selected_options()
	var save_flags: int = ResourceSaver.FLAG_COMPRESS + ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
	if not import_options.get("Compressed", true):
		save_flags = ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
	
	if not is_instance_valid(sprite_frames):
		return
	
	sprite_frames.take_over_path(path)
	ResourceSaver.save(sprite_frames, path, save_flags)


func parse_all_sparrows() -> SpriteFrames:
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")
	
	for import_path: String in imported_list.keys():
		assert(import_path != null, "Imported Sparrow Atlas needs valid path")
		
		var import_frames: SpriteFrames = imported_list.get(import_path)
		assert(is_instance_valid(import_frames), "Cannot use invalid SpriteFrames in export")
		
		if import_frames.get_animation_names().size() == 1:
			if import_frames.has_animation(&"default"):
				continue
		if import_frames.has_animation(&"default"):
			import_frames.remove_animation(&"default")
		
		for animation: String in import_frames.get_animation_names():
			var prefix: String = ("%s " % [get_path_prefix(import_path)]
				if import_frames.get_meta(&"path_prefix", import_path_prefix)
				else "")
			var export_name: String = "%s%s" % [prefix, animation]
			
			if not sprite_frames.has_animation(export_name):
				sprite_frames.add_animation(export_name)
				sprite_frames.set_animation_loop(export_name,
					import_frames.get_animation_loop(animation)
				)
				sprite_frames.set_animation_speed(export_name,
					import_frames.get_animation_speed(animation)
				)
			
			for index: int in import_frames.get_frame_count(animation):
				var texture: Texture2D = import_frames.get_frame_texture(
					animation,
					index,
				)
				
				if texture is AtlasTexture:
					texture.filter_clip = export_filter_edges
				if texture.has_meta(&"original_frame"):
					var frame: int = texture.get_meta(&"original_frame")
					if frame < sprite_frames.get_frame_count(export_name) - 1:
						sprite_frames.add_frame(
							export_name,
							texture,
							import_frames.get_frame_duration(
								animation,
								index,
							),
							frame,
						)
						continue
				
				sprite_frames.add_frame(
					export_name,
					texture,
					import_frames.get_frame_duration(
						animation,
						index,
					),
				)
	
	if export_clear_automatically:
		imported_list.clear()
		for child: Node in spritesheet_container.get_children():
			child.queue_free()
	
	if sprite_frames.get_animation_names().size() == 0:
		printerr("Will not export blank SpriteFrames. Try importing some functional spritesheets.")
		return null
	
	return sprite_frames


func import_sparrow_atlas(path: String) -> SpriteFrames:
	assert(FileAccess.file_exists(path), "File needs to exist to import.")
	assert(path.get_extension() == "xml", "File needs to have .xml extension to be a Sparrow Atlas!")
	
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	if sprite_frames.has_animation(&"default"):
		sprite_frames.remove_animation(&"default")
	
	var xml_parser: XMLParser = XMLParser.new()
	xml_parser.open(path)
	
	var source_texture: Texture2D = null
	var source_image: Image = null
	var cached_frames: Dictionary[Array, AtlasTexture] = {}
	var frames: Array[Array] = []
	
	while xml_parser.read() != ERR_FILE_EOF:
		# We only need elements for this format,
		# so skip past anything else
		if xml_parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		
		var node_name: String = xml_parser.get_node_name().to_lower()
		match node_name:
			"textureatlas":
				var texture_path: String = "%s/%s" % [
					path.get_base_dir(),
					xml_parser.get_named_attribute_value_safe("imagePath"),
				]
				
				if not ResourceLoader.exists(texture_path):
					texture_path = "%s.png" % [path.get_basename()]
				
				if ResourceLoader.exists(texture_path):
					source_texture = load(ResourceUID.path_to_uid(texture_path))
			"subtexture":
				assert(xml_parser.has_attribute("name"), "SubTexture needs \"name\" attribute to be parsed as a frame.")
				assert(xml_parser.has_attribute("x"), "SubTexture needs \"x\" attribute to be parsed as a frame.")
				assert(xml_parser.has_attribute("y"), "SubTexture needs \"y\" attribute to be parsed as a frame.")
				assert(xml_parser.has_attribute("width"), "SubTexture needs \"width\" attribute to be parsed as a frame.")
				assert(xml_parser.has_attribute("height"), "SubTexture needs \"height\" attribute to be parsed as a frame.")
				
				var frame_name: String = xml_parser.get_named_attribute_value("name")
				var frame_name_array: PackedStringArray = parse_animation_name(frame_name)
				var parsed_name: String = frame_name_array[0]
				var parsed_numbers: String = frame_name_array[1]
				
				var frame_rotated: String = xml_parser.get_named_attribute_value_safe("rotated")
				var rotated: bool = frame_rotated == "true"
				
				var frame_x: String = xml_parser.get_named_attribute_value("x")
				var frame_y: String = xml_parser.get_named_attribute_value("y")
				var frame_width: String = xml_parser.get_named_attribute_value("width")
				var frame_height: String = xml_parser.get_named_attribute_value("height")
				
				assert(frame_x.is_valid_float(), "SubTextures must have a valid \"x\" coordinate to be parsed correctly.")
				assert(frame_y.is_valid_float(), "SubTextures must have a valid \"y\" coordinate to be parsed correctly.")
				assert(frame_width.is_valid_float(), "SubTextures must have a valid \"width\" coordinate to be parsed correctly.")
				assert(frame_height.is_valid_float(), "SubTextures must have a valid \"height\" coordinate to be parsed correctly.")
				
				var source_rect: Rect2 = Rect2(
					Vector2(
						float(frame_x),
						float(frame_y),
					),
					Vector2(
						float(frame_width),
						float(frame_height),
					),
				)
				
				if rotated:
					source_rect.size = Vector2(source_rect.size.y, source_rect.size.x)
				
				var offset_rect: Rect2 = Rect2(
					Vector2.ZERO,
					Vector2.ZERO,
				)
				
				var offset_x: String = xml_parser.get_named_attribute_value_safe("frameX")
				var offset_y: String = xml_parser.get_named_attribute_value_safe("frameY")
				var bounds_width: String = xml_parser.get_named_attribute_value_safe("frameWidth")
				var bounds_height: String = xml_parser.get_named_attribute_value_safe("frameHeight")
				if offset_x.is_valid_float() and bounds_width.is_valid_float():
					offset_rect.position.x = absf(float(offset_x))
					offset_rect.size.x = int(bounds_width) - source_rect.size.x
				if offset_y.is_valid_float() and bounds_height.is_valid_float():
					offset_rect.position.y = absf(float(offset_y))
					offset_rect.size.y = float(bounds_height) - source_rect.size.y
				
				var texture: Texture2D = null
				for pair: Array in cached_frames.keys():
					if (pair[0] == source_rect and
						pair[1] == offset_rect and
						pair[2] == rotated):
						texture = cached_frames.get(pair)
						break
				
				if not is_instance_valid(texture):
					if rotated:
						if not is_instance_valid(source_image):
							source_image = source_texture.get_image()
						
						var image: Image = source_image.get_region(Rect2i(
							source_rect.position,
							Vector2(
								source_rect.size.y,
								source_rect.size.x,
							),
						))
						image.rotate_90(COUNTERCLOCKWISE)
						
						texture = AtlasTexture.new()
						texture.atlas = ImageTexture.create_from_image(image)
						texture.region = Rect2(
							Vector2.ZERO,
							source_rect.size,
						)
						texture.margin = offset_rect
					else:
						texture = AtlasTexture.new()
						texture.atlas = source_texture
						texture.region = source_rect
						texture.margin = offset_rect
					
					texture.set_meta(&"original_frame", int(parsed_numbers))
					cached_frames.set([
						source_rect,
						offset_rect,
						rotated,
					], texture)
				
				if not sprite_frames.has_animation(parsed_name):
					sprite_frames.add_animation(parsed_name)
					sprite_frames.set_animation_loop(parsed_name, import_looping)
					sprite_frames.set_animation_speed(parsed_name, import_framerate)
				
				frames.push_back(
					[
						int(parsed_numbers),
						parsed_name,
						texture,
					]
				)
			_:
				pass
	
	# Sort based on lowest frame count first.
	frames.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0]
	)
	
	for frame_data: Array in frames:
		var animation: String = frame_data[1]
		var texture: Texture2D = frame_data[2]
		sprite_frames.add_frame(animation, texture)
	
	sprite_frames.set_meta(&"path_prefix", import_path_prefix)
	return sprite_frames


func parse_animation_name(frame_name: String) -> PackedStringArray:
	const NUMBERS: String = "0123456789"
	if frame_name.is_empty():
		return ["", ""]
	
	var found_numbers: bool = false
	var starting_numbers: bool = true
	var index: int = frame_name.length() - 1
	var stop_index: int = frame_name.length() - 1
	while index >= 0:
		var character: String = frame_name[index]
		if starting_numbers:
			if (not NUMBERS.contains(character)) or index < frame_name.length() - 4:
				starting_numbers = false
				stop_index = index + 1
				break
			else:
				found_numbers = true
		
		index -= 1
	
	if starting_numbers:
		return ["", frame_name]
	
	return [
		frame_name.substr(0, stop_index),
		frame_name.substr(stop_index, frame_name.length() - 1)
	]
