@tool
extends Control


signal dropped_spritesheet(path: String)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data.has("files"):
		return false
	
	var texture_extensions: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type("Texture2D")
	var has_any: bool = false
	for file: String in data.get("files"):
		if texture_extensions.has(file.get_extension()) or file.get_extension() == "xml":
			has_any = true
			break
	
	return has_any


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var files: PackedStringArray = data.get("files")
	for file: String in files:
		if file.get_extension() == "xml":
			dropped_spritesheet.emit(file)
			continue
		
		var resource: Resource = load(file)
		if resource is not Texture2D:
			continue
		
		dropped_spritesheet.emit("%s.xml" % [file.get_basename()])
