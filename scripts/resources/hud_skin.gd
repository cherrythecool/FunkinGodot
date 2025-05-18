class_name HUDSkin extends Resource


@export_group('Ratings')

@export var marvelous: Texture2D = load('uid://cn6fmp8et8ktw')
@export var sick: Texture2D = load('uid://gn12nu6v7fgf')
@export var good: Texture2D = load('uid://c48jhvhvs2fdc')
@export var bad: Texture2D = load('uid://bfte1efl00hqd')
@export var shit: Texture2D = load('uid://ccnsbyha7asga')
@export var rating_scale: Vector2 = Vector2(0.7, 0.7)
@export var rating_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Combo')

@export var combo_atlas: Texture2D = load('uid://ds3g63uwcq4jw')
@export var combo_scale: Vector2 = Vector2(0.5, 0.5)
@export var combo_spacing: float = 90.0
@export var combo_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Countdown')

@export var countdown_textures: Array[Texture2D] = [
	null,
	load('uid://cd4erocsrgekg'),
	load('uid://c70k6xe0qbuac'),
	load('uid://cgkt2ctlovm34'),
]

@export var countdown_sounds: Array[AudioStream] = [
	load('uid://vusu7c2ire01'),
	load('uid://dj08aj6avwys5'),
	load('uid://cvne10g6br5tx'),
	load('uid://b2d2bpdv1aaa6'),
]

@export var countdown_scale: Vector2 = Vector2(0.7, 0.7)
@export var countdown_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Misc')

@export var pause_menu: PackedScene = null
@export var pause_music: AudioStream = null
