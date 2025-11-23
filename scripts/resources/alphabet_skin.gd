@tool
extends Resource
class_name AlphabetSkin


@export var sprite_frames: SpriteFrames = null
@export var character_map: Dictionary[PackedStringArray, AlphabetSkinCharacter] = {}
@export var space_width: float = 34.0

var optimized_map: Dictionary[String, AlphabetSkinCharacter] = {}


func bake_optimized_map() -> void:
	for key: PackedStringArray in character_map.keys():
		for value: String in key:
			optimized_map.set(value, character_map.get(key))
