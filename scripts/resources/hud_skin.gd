class_name HUDSkin extends Resource


@export_group('Ratings')

@export var marvelous: Texture2D = null
@export var sick: Texture2D = null
@export var good: Texture2D = null
@export var bad: Texture2D = null
@export var shit: Texture2D = null
@export var rating_scale: Vector2 = Vector2(0.7, 0.7)
@export var rating_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Combo')

@export var combo_atlas: Texture2D = null
@export var combo_scale: Vector2 = Vector2(0.5, 0.5)
@export var combo_spacing: float = 90.0
@export var combo_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Countdown')

@export var countdown_textures: Array[Texture2D] = [
	null,
	null,
	null,
	null,
]

@export var countdown_sounds: Array[AudioStream] = [
	null,
	null,
	null,
	null,
]

@export var countdown_scale: Vector2 = Vector2(0.7, 0.7)
@export var countdown_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Misc')

@export var pause_menu: PackedScene = null
@export var pause_music: AudioStream = null


func get_combo_atlas() -> Texture2D:
	if is_instance_valid(combo_atlas):
		return combo_atlas
	return load("uid://ds3g63uwcq4jw")


func get_countdown_textures(length: int = 4) -> Array[Texture2D]:
	const DEFAULT_PATHS: Dictionary[int, String] = {
		1: "uid://cd4erocsrgekg",
		2: "uid://c70k6xe0qbuac",
		3: "uid://cgkt2ctlovm34",
	}
	
	var textures: Array[Texture2D] = []
	for i: int in length:
		if (i < countdown_textures.size() and
			is_instance_valid(countdown_textures[i])):
			textures.push_back(countdown_textures[i])
		elif DEFAULT_PATHS.has(i):
			textures.push_back(load(DEFAULT_PATHS[i]))
		else:
			textures.push_back(null)
	
	return textures


func get_countdown_sounds(length: int = 4) -> Array[AudioStream]:
	const DEFAULT_PATHS: Dictionary[int, String] = {
		0: "uid://vusu7c2ire01",
		1: "uid://dj08aj6avwys5",
		2: "uid://cvne10g6br5tx",
		3: "uid://b2d2bpdv1aaa6",
	}
	
	var sounds: Array[AudioStream] = []
	for i: int in length:
		if (i < countdown_sounds.size() and
			is_instance_valid(countdown_sounds[i])):
			sounds.push_back(countdown_sounds[i])
		elif DEFAULT_PATHS.has(i):
			sounds.push_back(load(DEFAULT_PATHS[i]))
		else:
			sounds.push_back(null)
	
	return sounds


func get_rating_textures() -> Dictionary[StringName, Texture2D]:
	const DEFAULT_PATHS: Dictionary[StringName, String] = {
		&"marvelous": "uid://cn6fmp8et8ktw",
		&"sick": "uid://gn12nu6v7fgf",
		&"good": "uid://c48jhvhvs2fdc",
		&"bad": "uid://bfte1efl00hqd",
		&"shit": "uid://ccnsbyha7asga",
	}
	
	var textures: Dictionary[StringName, Texture2D] = {}
	for key: StringName in DEFAULT_PATHS.keys():
		if key in self and is_instance_valid(get(key)):
			textures[key] = get(key)
		else:
			textures[key] = load(DEFAULT_PATHS[key])
	
	return textures
