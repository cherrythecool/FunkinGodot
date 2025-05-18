@tool
class_name Alphabet extends Node2D


@export var no_casing: bool = true
@export var frames: SpriteFrames = null
@export var suffix: String = ' bold'

@export_multiline var text: String = '':
	set(value):
		if text == value:
			return
		text = value
		_create_characters()

@export var centered: bool = false:
	set(value):
		if centered == value:
			return
		centered = value
		_create_characters()

@export var no_offset: bool = false

@export_enum('Left', 'Center', 'Right') var horizontal_alignment: String = 'Left':
	set(value):
		if horizontal_alignment == value:
			return
		horizontal_alignment = value
		_create_characters()

const UNCHANGED_CHARACTERS: StringName = &'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const MAGIC_OFFSET: float = 20.0

var size: Vector2i = Vector2i.ZERO

signal updated


func _ready() -> void:
	_create_characters()


func _create_characters() -> void:
	for child: AnimatedSprite2D in get_children():
		child.queue_free()

	size = Vector2i.ZERO

	var x_position: float = 0.0
	var y_position: float = 0.0
	var lines: Array[Dictionary] = []
	var line_index: int = 0

	for character: String in text:
		if lines.size() - 1 < line_index:
			lines.push_back({
				'size': Vector2i.ZERO,
				'characters': [],
			})

		if character == ' ':
			x_position += 50.0
			continue
		if character == '\n':
			x_position = 0.0
			y_position += 70.0
			line_index += 1
			continue

		var character_data: Array = _create_character(x_position, y_position, character)
		add_child(character_data[0])

		x_position += character_data[1].x

		if x_position > size.x:
			size.x = roundi(x_position)
		if y_position + character_data[1].y > size.y:
			size.y = y_position + character_data[1].y

		var line_dict: Dictionary = lines[line_index]
		line_dict.get('characters', []).push_back(character_data[0])
		var line_size: Vector2i = line_dict.get('size', Vector2i.ZERO)
		# x should basically be always true lol
		if x_position > line_size.x:
			line_size.x = roundi(x_position)
		if y_position + character_data[1].y > line_size.y:
			line_size.y = roundi(y_position + character_data[1].y)

		line_dict['size'] = line_size

	if centered:
		for child: AnimatedSprite2D in get_children():
			child.position -= size * 0.5

	match horizontal_alignment:
		'Left':
			pass
		'Center', 'Right':
			for line: Dictionary in lines:
				var characters: Array = line.get('characters', [])
				var line_size: Vector2i = line.get('size', Vector2i.ZERO)

				if characters.is_empty() or line_size <= Vector2i.ZERO:
					continue
				for character: AnimatedSprite2D in characters:
					if horizontal_alignment == 'Center':
						character.position.x += (size.x - line_size.x) / 2.0
					else: # Right
						character.position.x -= line_size.x - size.x

	updated.emit()


func _create_character(x: float, y: float, character: String) -> Array:
	var animation_data: AlphabetAnimationData = _character_to_animation(character)
	var node: AnimatedSprite2D = AnimatedSprite2D.new()
	node.use_parent_material = true
	node.centered = false
	if is_instance_valid(frames):
		node.sprite_frames = frames
	else:
		node.sprite_frames = load('uid://dqo7xiv07wfyc')
	node.position = Vector2(x, y)
	node.animation = animation_data.name + suffix
	node.offset = animation_data.offset
	node.play()

	var character_size: Vector2 = Vector2.ZERO
	if node.sprite_frames.has_animation(node.animation):
		var frame_texture: Texture2D = node.sprite_frames.get_frame_texture(node.animation, 0)
		character_size = frame_texture.get_size()
	node.offset.y -= (character_size.y - 65.0) / 2.0
	return [node, character_size]


func _character_to_animation(character: String) -> AlphabetAnimationData:
	var data: AlphabetAnimationData = AlphabetAnimationData.new()
	if UNCHANGED_CHARACTERS.contains(character.to_upper()):
		data.name = character.to_lower() if no_casing else character
		data.offset = Vector2.ZERO
		return data

	# all used by bold.xml, not sure about default.xml support rn :3
	match character:
		'\'', '‘', '’':
			data.name = 'apostrophe'
			data.offset.y = -MAGIC_OFFSET
		'\\':
			data.name = 'back slash'
		',':
			data.name = 'apostrophe' # data.name = 'comma'
			data.offset.y = MAGIC_OFFSET
		'“', '"':
			data.name = 'start quote'
			data.offset.y = -MAGIC_OFFSET
		'”':
			data.name = 'end quote'
			data.offset.y = -MAGIC_OFFSET
		'!':
			data.name = 'exclamation'
		'/':
			data.name = 'forward slash'
		'♥', '❤️':
			data.name = 'heart'
		'×':
			data.name = 'multiply x'
		'.':
			data.name = 'period'
			data.offset.y = MAGIC_OFFSET
		'?':
			data.name = 'question'
		'←':
			data.name = 'left arrow'
		'↓':
			data.name = 'down arrow'
		'↑':
			data.name = 'up arrow'
		'→':
			data.name = 'right arrow'
		':':
			data.name = character
		'_':
			data.name = '-'
			data.offset.y = MAGIC_OFFSET * 1.5
		'ñ':
			data.name = character
			data.offset.y = -MAGIC_OFFSET * 0.6
		_:
			data.name = character

	if no_offset:
		data.offset = Vector2.ZERO

	return data


static func keycode_to_character(input: Key) -> String:
	return string_to_character(OS.get_keycode_string(input))


static func string_to_character(input: String) -> String:
	match input.to_lower():
		'apostrophe':
			return '"'
		'backslash':
			return '\\'
		'comma':
			return ','
		'period':
			return '.'
		'semicolon':
			return ':'
		'slash':
			return '/'
		'minus':
			return '-'
		'left':
			return '<'
		'down':
			return 'v'
		'up':
			return 'ô'
		'right':
			return '>'

	return input


class AlphabetAnimationData extends RefCounted:
	var name: StringName
	var offset: Vector2
