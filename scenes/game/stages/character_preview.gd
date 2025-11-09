@tool
class_name CharacterPlacement extends Node2D


@export_file('*.tscn') var character_path: String = "res://scenes/game/characters/bf.tscn":
	set(value):
		character_path = value
		if Engine.is_editor_hint():
			queue_redraw()
@export var flipped: bool = false:
	set(value):
		flipped = value
		if Engine.is_editor_hint():
			queue_redraw()

var character: Node = null


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if not ResourceLoader.exists(character_path):
		return
	if character:
		character.queue_free()

	var scene: PackedScene = load(character_path)
	character = scene.instantiate()
	character.modulate.a = 0.5
	if flipped:
		character.scale.x *= -1.0
	add_child(character)


func adjust_character(input: Character, set_player: bool = false) -> void:
	input.global_position = global_position
	if set_player:
		input.is_player = set_player
	input.scale *= scale
	input.z_index += z_index
	
	if is_instance_valid(material):
		input.set_character_material(material)
	if has_node(^"camera_offset"):
		if is_instance_valid(input.camera_offset):
			input.camera_offset.queue_free()
		input.camera_offset = get_node(^"camera_offset")
		input.camera_offset.owner = null
		input.camera_offset.reparent(input)


func instance_character(player: bool = false, insert: bool = true) -> Character:
	if not ResourceLoader.exists(character_path):
		printerr("Couldn't find character at path %s!" % [character_path])
		return null

	var scene: PackedScene = load(character_path)
	var instanced: Character = scene.instantiate()
	if flipped:
		instanced.scale.x *= -1.0
	instanced.is_player = player
	instanced.scale *= scale
	instanced.z_index += z_index
	if insert:
		add_sibling(instanced)
	
	if is_instance_valid(material):
		instanced.set_character_material(material)
	if has_node(^"camera_offset"):
		if is_instance_valid(instanced.camera_offset):
			instanced.camera_offset.queue_free()
		instanced.camera_offset = get_node(^"camera_offset")
	
	return instanced
