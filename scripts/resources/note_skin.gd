extends Resource
class_name NoteSkin


@export_group("Strums", "strum_")
@export var strum_frames: SpriteFrames = null
@export var strum_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var strum_scale: Vector2 = Vector2.ONE * 0.7

@export_group("Notes", "note_")
@export var note_frames: SpriteFrames = null
@export var note_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var note_scale: Vector2 = Vector2.ONE * 0.7

@export_group("Sustains", "sustain_")
@export_range(0.0, 1.0, 0.001) var sustain_alpha: float = 0.7
@export_range(0.0, 100.0, 1.0, "or_greater") var sustain_size: float = 35.0
@export var sustain_texture_offset: Rect2 = Rect2(0.0, 0.0, 0.0, -2.0)
@export var sustain_tile_texture: bool = false
@export var sustain_tile_mirroring: bool = false

@export_subgroup("Sustain Tails", "sustain_tail_")
@export var sustain_tail_texture_offset: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)
@export_range(0.0, 100.0, 1.0, "or_greater") var sustain_tail_size: float = 35.0
@export var sustain_tail_offset: float = 0.0

@export_group("Note Splashes", "splash_")
@export var splash_frames: SpriteFrames = null
@export var splash_filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export var splash_scale: Vector2 = Vector2.ONE
@export var splash_use_default_shader: bool = true
@export var splash_colors: Array[Color] = [
	Color("c14b99"),
	Color("00ffff"),
	Color("12fa04"),
	Color("f9393f"),
]


func get_strum_frames() -> SpriteFrames:
	if is_instance_valid(strum_frames):
		return strum_frames
	return load("uid://y8en4nx7mbuw")


func get_note_frames() -> SpriteFrames:
	if is_instance_valid(note_frames):
		return note_frames
	return load("uid://b3r2xop0whqyf")


func get_splash_frames() -> SpriteFrames:
	if is_instance_valid(splash_frames):
		return splash_frames
	return load("uid://bw4etux81oui3")
