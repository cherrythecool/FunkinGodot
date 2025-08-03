class_name HUDSkin extends Resource


@export_group('Ratings')

@export var marvelous: Texture2D = preload('uid://cn6fmp8et8ktw')
@export var sick: Texture2D = preload('uid://gn12nu6v7fgf')
@export var good: Texture2D = preload('uid://gn12nu6v7fgf')
@export var bad: Texture2D = preload('uid://bfte1efl00hqd')
@export var shit: Texture2D = preload('uid://ccnsbyha7asga')
@export var rating_scale: Vector2 = Vector2(0.7, 0.7)
@export var rating_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Combo')

@export var combo_atlas: Texture2D = preload('uid://ds3g63uwcq4jw')
@export var combo_scale: Vector2 = Vector2(0.5, 0.5)
@export var combo_spacing: float = 90.0
@export var combo_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Countdown')

@export var countdown_textures: Array[Texture2D] = [
	null,
	preload('uid://cd4erocsrgekg'),
	preload('uid://c70k6xe0qbuac'),
	preload('uid://cgkt2ctlovm34'),
]

@export var countdown_sounds: Array[AudioStream] = [
	preload('uid://vusu7c2ire01'),
	preload('uid://dj08aj6avwys5'),
	preload('uid://cvne10g6br5tx'),
	preload('uid://b2d2bpdv1aaa6'),
]

@export var countdown_scale: Vector2 = Vector2(0.7, 0.7)
@export var countdown_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE

@export_group('Misc')

@export var pause_menu: PackedScene = null
@export var pause_music: AudioStream = null
