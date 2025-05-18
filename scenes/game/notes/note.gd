class_name Note extends Node2D


@export var sing_suffix: StringName = &''
@export var use_skin: bool = true
@export var splash: PackedScene = null

var data: NoteData
var lane: int = 0
var length: float = 0.0:
	set(v):
		length = v
		_update_sustain()

const directions: PackedStringArray = ['left', 'down', 'up', 'right']

@onready var sprite: AnimatedSprite = $sprite
@onready var clip_rect: Control = $clip_rect
@onready var sustain: TextureRect = clip_rect.get_node('sustain')
@onready var tail: TextureRect = sustain.get_node('tail')

var _hit: bool = false
var _sustain_offset: float = 0.0
var _field: NoteField = null
var _character: Character = null
var _previous_step: int = -128


func _ready() -> void:
	length = data.length

	# this is technically just temporary as it gets set again later on but whatever
	lane = absi(data.direction) % directions.size()

	sprite.animation = '%s note' % [directions[lane]]
	sprite.play()

	if not is_instance_valid(_field):
		_field = get_parent().get_parent()

	if length > 0.0:
		reload_sustain_sprites()
		if Config.get_value('interface', 'sustain_layer') == 'below':
			sustain.z_index -= 1
		_update_sustain()
	else:
		clip_rect.free()


func _process(delta: float) -> void:
	if not _hit:
		return

	if length <= 0.0:
		if is_instance_valid(_character):
			_character.sing(self, true)
		free()
		return

	sprite.visible = false
	length -= delta

	var step: int = floori(Conductor.step)
	if step > _previous_step:
		if is_instance_valid(_character):
			_character.sing(self, true)
		if is_instance_valid(_field):
			# Because of how this is coded this will simply play
			# the press animation over and over rather than
			# actually trying to hit the same note multiple times.
			_field._on_hit_note(self)
			_field.get_receptor_from_lane(lane).hit_note(self)

		_previous_step = step


func _update_sustain() -> void:
	if not is_instance_valid(_field):
		return

	if data.length < 0.0 or not is_instance_valid(sustain):
		return

	sustain.size.y = data.length * 1000.0 * 0.45 * (_field._scroll_speed * absf(_field._scroll_speed_modifier)) \
			/ scale.y - tail.size.y
	clip_rect.size.y = sustain.size.y + tail.size.y + 256.0

	var clip_target: float = _field._receptors[lane].position.y
	# I forgot the scale.y so many times but this works
	# as longg as the clip rect is big enough to fill the
	# whole screen (which it is rn because -1280 is more
	# than enough at 0.7 scale, which is the default)
	if _field._scroll_speed_modifier < 0.0:
		tail.pivot_offset.y = 0.0
		tail.position.y = -tail.size.y
		tail.flip_h = true
		tail.flip_v = true

		clip_rect.position.y = -clip_rect.size.y
		sustain.position.y = clip_rect.size.y - sustain.size.y

		if _hit:
			clip_rect.position.y += clip_target - (position.y / scale.y)
			sustain.position.y += position.y / scale.y
	else:
		tail.pivot_offset.y = tail.size.y
		tail.position.y = sustain.size.y
		tail.flip_h = false
		tail.flip_v = false

		if _hit:
			clip_rect.position.y = clip_target - position.y / scale.y
			sustain.position.y = position.y / scale.y
		else:
			clip_rect.position.y = 0.0
			sustain.position.y = 0.0

	sustain.position.y += (_sustain_offset / scale.y) * 1000.0 * 0.45 * \
			(_field._scroll_speed * absf(_field._scroll_speed_modifier))


func reload_sustain_sprites() -> void:
	if not is_instance_valid(sustain):
		return

	var sustain_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture('%s sustain' % [
		directions[lane]
	], 0).duplicate()
	sustain_texture.region.position.y += 1
	sustain_texture.region.size.y -= 2

	sustain.texture = sustain_texture

	var tail_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture('%s sustain end' % [
		directions[lane]
	], 0).duplicate()
	tail_texture.region.position.y += 1
	tail_texture.region.size.y -= 1

	tail.texture = tail_texture
	tail.size.y = tail.texture.get_height()

	clip_rect.pivot_offset.x = clip_rect.size.x / 2.0
