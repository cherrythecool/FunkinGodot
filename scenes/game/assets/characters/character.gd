class_name Character extends Node2D


@export_category('Visuals')
@export var icon: Icon = Icon.new()
@export var starts_as_player: bool = false

@export_category('Animations')
@export var dance_steps: Array[StringName] = [&'idle']
@export_range(0.0, 1024.0, 0.01) var sing_steps: float = 4.0
var dance_step: int = 0

@export_category('Death')
@export_file('*.tscn') var death_character: String = 'res://scenes/game/assets/characters/bf-dead.tscn'
@export var gameover_assets: GameoverAssets

@warning_ignore('unused_private_class_variable')
@onready var camera_offset: Node2D = $camera_offset
@onready var animation_player: AnimationPlayer = $animation_player

var is_player: bool = false
var animation: StringName = &''
var singing: bool = false
var sing_timer: float = 0.0
var in_special_anim: bool = false
var sprite: CanvasItem = null

signal animation_finished(animation: StringName)


func _ready() -> void:
	if has_node(^'sprite'):
		sprite = $sprite

	dance(true)
	animation_player.animation_finished.connect(func(anim_name: StringName) -> void:
		animation_finished.emit(anim_name)
	)


func play_anim(anim: StringName, force: bool = false, special: bool = false) -> void:
	if (in_special_anim and not force) and animation_player.is_playing():
		return
	if not has_anim(anim):
		push_warning('Character missing animation "%s"!' % [anim])
		return

	in_special_anim = special
	animation = anim
	singing = animation.begins_with(&'sing_')

	if animation_player.current_animation == anim and force:
		animation_player.seek(0.0, true)
		return

	animation_player.play(anim)


func has_anim(anim: StringName) -> bool:
	return animation_player.has_animation(anim)


func sing(note: Note, force: bool = false) -> void:
	sing_timer = 0.0

	const swapped: PackedStringArray = [&'left', &'right']
	var direction: StringName = Note.directions[note.lane]

	if is_player != starts_as_player and swapped.has(direction):
		direction = swapped[wrapi(swapped.find(direction) + 1, 0, swapped.size())]

	if (not note.sing_suffix.is_empty()) and \
			has_anim(&'sing_%s%s' % [direction.to_lower(), note.sing_suffix]):
		play_anim(&'sing_%s%s' % [direction.to_lower(), note.sing_suffix], force)
	else:
		play_anim(&'sing_%s' % direction.to_lower(), force)


func sing_miss(note: Note, force: bool = false) -> void:
	sing_timer = 0.0

	const swapped: PackedStringArray = [&'left', &'right']
	var direction: StringName = Note.directions[note.lane]

	if is_player != starts_as_player and swapped.has(direction):
		direction = swapped[wrapi(swapped.find(direction) + 1, 0, swapped.size())]

	play_anim(&'sing_%s_miss' % direction.to_lower(), force)


func dance(force: bool = false) -> void:
	if singing and not force:
		return
	if dance_steps.is_empty():
		return
	if dance_steps.size() > 1:
		dance_step = wrapi(dance_step + 1, 0, dance_steps.size())
		play_anim(dance_steps[dance_step], force)
		return

	play_anim(dance_steps[0], force)


func set_character_material(new_material: Material) -> void:
	if is_instance_valid(sprite):
		sprite.material = new_material


func _process(delta: float) -> void:
	if singing:
		sing_timer += delta / Conductor.beat_delta
		if sing_timer * 4.0 >= sing_steps or sing_steps <= 0.0:
			dance(true)
