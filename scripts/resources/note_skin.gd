class_name NoteSkin extends Resource


@export var strum_frames: SpriteFrames = load('uid://y8en4nx7mbuw')
@export_enum(
		'Inherit', 'Nearest', 'Linear',
		'Nearest Mipmap', 'Linear Mipmap',
		'Nearest Mipmap Anisotropic', 'Linear Mipmap Anisotropic'
) var strum_filter: int = 0
@export var strum_scale: Vector2 = Vector2.ONE * 0.7

# this not being a uid pisses me off but i can't get a uid from the notes for some reason so
@export var note_frames: SpriteFrames = load('res://assets/game/skins/default/notes.res')
@export_enum(
		'Inherit', 'Nearest', 'Linear',
		'Nearest Mipmap', 'Linear Mipmap',
		'Nearest Mipmap Anisotropic', 'Linear Mipmap Anisotropic'
) var note_filter: int = 0
@export var note_scale: Vector2 = Vector2.ONE * 0.7
@export_range(0.0, 1.0, 0.001) var sustain_alpha: float = 0.7

@export var splash_frames: SpriteFrames = load('uid://bw4etux81oui3')
@export_enum(
		'Inherit', 'Nearest', 'Linear',
		'Nearest Mipmap', 'Linear Mipmap',
		'Nearest Mipmap Anisotropic', 'Linear Mipmap Anisotropic'
) var splash_filter: int = 0
@export var splash_scale: Vector2 = Vector2.ONE
