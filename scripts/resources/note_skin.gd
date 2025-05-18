class_name NoteSkin extends Resource


@export var strum_frames: SpriteFrames = load('uid://y8en4nx7mbuw')
@export var strum_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var strum_scale: Vector2 = Vector2.ONE * 0.7

# this not being a uid pisses me off but i can't get a uid from the notes for some reason so
@export var note_frames: SpriteFrames = load('res://assets/game/skins/default/notes.res')
@export var note_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var note_scale: Vector2 = Vector2.ONE * 0.7
@export_range(0.0, 1.0, 0.001) var sustain_alpha: float = 0.7

@export var splash_frames: SpriteFrames = load('uid://bw4etux81oui3')
@export var splash_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var splash_scale: Vector2 = Vector2.ONE
