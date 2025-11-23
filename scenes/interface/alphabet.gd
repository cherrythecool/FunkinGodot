@tool
class_name Alphabet extends Node2D


@export_enum("Inherit", "Force Upper", "Force Lower") var casing: String = "Inherit":
	set(v):
		if casing == v:
			return
		casing = v
		_create_characters()

@export var suffix: String = ' bold':
	set(v):
		if suffix == v:
			return
		suffix = v
		_create_characters()

@export var line_spacing: float = 70.0:
	set(v):
		if line_spacing == v:
			return
		line_spacing = v
		_create_characters()

@export var skin: AlphabetSkin = null:
	set(v):
		if skin == v:
			return
		skin = v
		if is_instance_valid(skin):
			skin.bake_optimized_map()
		_create_characters()
@export var overwrite_map: Dictionary[StringName, AlphabetSkinCharacter] = {}

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
@export_enum('Top', 'Center', 'Bottom') var vertical_alignment: String = 'Center':
	set(value):
		if vertical_alignment == value:
			return
		vertical_alignment = value
		_create_characters()

var size: Vector2i = Vector2i.ZERO

signal updated


func _ready() -> void:
	_create_characters()


func _create_characters() -> void:
	if not is_instance_valid(skin):
		skin = load("uid://5kr5cxye6wyn")
	
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
			x_position += skin.space_width
			continue
		if character == '\n':
			x_position = 0.0
			y_position += line_spacing
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
	match casing:
		'Force Upper':
			character = character.to_upper()
		'Force Lower':
			character = character.to_lower()
		'Inherit':
			pass
	
	var skin_char: AlphabetSkinCharacter = overwrite_map.get(
		character,
		skin.optimized_map.get(character)
	)
	
	var node: AnimatedSprite2D = AnimatedSprite2D.new()
	node.use_parent_material = true
	node.centered = false
	node.sprite_frames = skin.sprite_frames
	node.position = Vector2(x, y)
	
	if is_instance_valid(skin_char):
		node.offset = skin_char.offset
		
		if node.sprite_frames.has_animation(skin_char.animation + suffix):
			node.animation = skin_char.animation + suffix
		elif node.sprite_frames.has_animation(skin_char.animation.to_upper() + suffix):
			node.animation = skin_char.animation.to_upper() + suffix
		else:
			node.visible = false
	else:
		node.offset = Vector2.ZERO
		
		if node.sprite_frames.has_animation(character + suffix):
			node.animation = character + suffix
		elif node.sprite_frames.has_animation(character.to_upper() + suffix):
			node.animation = character.to_upper() + suffix
		else:
			node.visible = false
	
	node.play()

	var character_size: Vector2 = Vector2.ZERO
	if node.visible:
		var frame_texture: Texture2D = node.sprite_frames.get_frame_texture(node.animation, 0)
		character_size = frame_texture.get_size()
	
	match vertical_alignment:
		'Bottom':
			node.offset.y += 60.0 - character_size.y
		'Top':
			node.offset.y = node.offset.y
		_:
			node.offset.y -= (character_size.y - 65.0) / 2.0
	
	return [node, character_size]


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
		'bracketright':
			return ']'
		'bracketleft':
			return '['
		'quoteleft':
			return '~'
		'left':
			return '←'
		'down':
			return '↓'
		'up':
			return '↑'
		'right':
			return '→'

	return input
