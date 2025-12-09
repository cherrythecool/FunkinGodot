class_name Note extends Node2D


const DEFAULT_HIT_WINDOW: float = 0.18
const DEFAULT_PATH: String = "uid://f75xq2p53bpl"

@export var sing_suffix: StringName = &""
@export var use_skin: bool = true
@export var splash: PackedScene = null
@export var hit_window: float = DEFAULT_HIT_WINDOW

var data: NoteData
var lane: int = 0
var length: float = 0.0:
	set(value):
		var update: bool = length != value
		length = value
		
		if update:
			update_sustain()
var is_sustain: bool = false

const directions: PackedStringArray = ["left", "down", "up", "right"]

@onready var sprite: AnimatedSprite = $sprite
@onready var clip_rect: Control = $clip_rect
@onready var sustain: TextureRect = clip_rect.get_node(^"sustain")
@onready var tail: TextureRect = sustain.get_node(^"tail")

var hit: bool = false
var field: NoteField = null
var character: Character = null
var previous_step: int = -128
var sustain_release_when_hit: float = 0.0
var sustain_end_time: float = 0.0
var sustain_timer: float = 0.0:
	set(v):
		if not is_sustain:
			return
		
		sustain_timer = v
		sustain.modulate.a = clampf(v / sustain_release_when_hit, 0.0, 1.0)
var sustain_length_offset: float = 0.0
var sustain_tail_offset: float = 0.0


func _ready() -> void:
	length = data.length

	# this is technically just temporary as it gets set again later on but whatever
	lane = absi(data.direction) % directions.size()

	sprite.animation = &"%s note" % [directions[lane]]
	sprite.play()

	if not is_instance_valid(field):
		field = get_parent().get_parent()

	if length > 0.0:
		is_sustain = true
		reload_sustain_sprites()
		if Config.get_value("interface", "sustain_layer") == "below":
			sustain.z_index -= 1
		update_sustain()
	else:
		clip_rect.hide()
		clip_rect.queue_free()


func _process(_delta: float) -> void:
	if not hit:
		return
	if not is_instance_valid(Conductor.instance):
		return
	if not is_sustain:
		if is_instance_valid(field):
			field.remove_note(self)
		return
	
	sprite.visible = false
	
	if sustain_end_time == 0.0:
		sustain_end_time = data.time + length
	length = sustain_end_time - Conductor.instance.time
	if length <= 0.0:
		if is_instance_valid(field):
			field.remove_note(self)
		return

	var step: int = floori(Conductor.instance.step)
	if step > previous_step:
		if is_instance_valid(field):
			# Because of how this is coded this will simply play
			# the press animation over and over rather than
			# actually trying to hit the same note multiple times.
			field.hit_note(self)
			
			if field.is_receptor_held(lane):
				field.get_receptor_from_lane(lane).hit_note(self)

		previous_step = step


func update_sustain() -> void:
	if not is_instance_valid(field):
		return
	if not is_sustain:
		return

	var time_factor: float = 1000.0 * 0.45 * absf(field.get_scroll_speed()) \
			/ scale.y - (tail.size.y * tail.scale.y)
	sustain.size.y = (data.length + sustain_length_offset) * time_factor
	clip_rect.size.y = sustain.size.y + (tail.size.y * tail.scale.y) + 256.0

	var clip_target: float = field.receptors[lane].position.y
	# I forgot the scale.y so many times but this works
	# as longg as the clip rect is big enough to fill the
	# whole screen (which it is rn because -1280 is more
	# than enough at 0.7 scale, which is the default)
	if field.scroll_speed_modifier < 0.0:
		tail.pivot_offset.y = 0.0
		tail.position.y = -tail.size.y
		tail.flip_h = true
		tail.flip_v = true

		clip_rect.position.y = -clip_rect.size.y
		sustain.position.y = clip_rect.size.y - sustain.size.y
		if hit:
			clip_rect.position.y += clip_target - (position.y / scale.y)
			sustain.position.y += position.y / scale.y
	else:
		tail.pivot_offset.y = tail.size.y
		tail.position.y = sustain.size.y
		tail.flip_h = false
		tail.flip_v = false

		if hit:
			clip_rect.position.y = clip_target - position.y / scale.y
			sustain.position.y = position.y / scale.y
		else:
			clip_rect.position.y = 0.0
			sustain.position.y = 0.0

	var offset_modifier: float = -1.0
	if field.scroll_speed_modifier < 0.0:
		offset_modifier = 1.0
	
	sustain.position.y += sustain_length_offset * time_factor * offset_modifier
	tail.position.x = sustain_tail_offset


func reload_sustain_sprites(skin: NoteSkin = null) -> void:
	if not is_sustain:
		return
	if not use_skin:
		return
	if not is_instance_valid(skin):
		skin = NoteSkin.new()

	var sustain_anim: StringName = &"%s sustain" % [directions[lane],]
	if sprite.sprite_frames.has_animation(sustain_anim):
		var sustain_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture(sustain_anim, 0).duplicate()
		sustain_texture.region.position += skin.sustain_texture_offset.position
		sustain_texture.region.size += skin.sustain_texture_offset.size
		sustain.texture = sustain_texture

	var tail_anim: StringName = &"%s sustain end" % [directions[lane],]
	if sprite.sprite_frames.has_animation(tail_anim):
		var tail_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture(tail_anim, 0).duplicate()
		tail_texture.region.position += skin.sustain_tail_texture_offset.position
		tail_texture.region.size += skin.sustain_tail_texture_offset.size
		tail.texture = tail_texture
		tail.size.y = tail.texture.get_height()

	clip_rect.scale.x = 1.0 / scale.x
	sustain.texture_filter = sprite.texture_filter
	sustain.modulate.a = skin.sustain_alpha
	sustain.size.x = skin.sustain_size
	tail.size.x = skin.sustain_tail_size
	sustain_tail_offset = skin.sustain_tail_offset
	
	clip_rect.size.x = maxf(sustain.size.x, tail.size.x) + 78.0
	clip_rect.position.x = -clip_rect.size.x / 2.0
	clip_rect.pivot_offset.x = clip_rect.size.x / 2.0
	sustain.position.x = (clip_rect.size.x - sustain.size.x) / 2.0
	
	if skin.sustain_tile_texture:
		sustain.set_script(load("uid://bwf4k5hxjoqaw"))
		sustain.mirror_every_other = skin.sustain_tile_mirroring
	elif sustain is AtlasTextureRect:
		sustain.set_script(null)


func note_hit() -> void:
	pass


func note_miss() -> void:
	pass
