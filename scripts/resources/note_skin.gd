class_name NoteSkin extends Resource


@export var strum_frames: SpriteFrames = preload('uid://y8en4nx7mbuw')
@export_enum(
		'Inherit', 'Nearest', 'Linear',
		'Nearest Mipmap', 'Linear Mipmap',
		'Nearest Mipmap Anisotropic', 'Linear Mipmap Anisotropic'
) var strum_filter: int = 0
@export var strum_scale: Vector2 = Vector2.ONE * 0.7

@export var note_frames: SpriteFrames = null#preload('res://assets/game/skins/default/notes.res')
@export_enum(
		'Inherit', 'Nearest', 'Linear',
		'Nearest Mipmap', 'Linear Mipmap',
		'Nearest Mipmap Anisotropic', 'Linear Mipmap Anisotropic'
) var note_filter: int = 0
@export var note_scale: Vector2 = Vector2.ONE * 0.7
@export_range(0.0, 1.0, 0.001) var sustain_alpha: float = 0.7

@export var splash_frames: SpriteFrames = preload('uid://bw4etux81oui3')
@export_enum(
		'Inherit', 'Nearest', 'Linear',
		'Nearest Mipmap', 'Linear Mipmap',
		'Nearest Mipmap Anisotropic', 'Linear Mipmap Anisotropic'
) var splash_filter: int = 0
@export var splash_scale: Vector2 = Vector2.ONE
