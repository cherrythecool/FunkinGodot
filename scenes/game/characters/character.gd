class_name Character extends Node2D


@export_category("Visuals")
@export var icon: Icon = Icon.new()
@export var starts_as_player: bool = false

@export_category("Animations")
@export var dances: bool = true
@export var dance_steps: Array[StringName] = [&"idle"]
@export_range(0.0, 1024.0, 0.01) var sing_steps: float = 4.0
var dance_step: int = 0

@export_category("Death")
@export_file("*.tscn") var death_character: String = "uid://w4v0gymuehdt"
@export var gameover_assets: GameoverAssets

@onready var camera_offset: Node2D = $camera_offset
@onready var animation_player: AnimationPlayer = $animation_player

var swap_sing_animations: bool = false
var animation: StringName = &""
var singing: bool = false
var sing_timer: float = 0.0
var in_special_anim: bool = false
var sprite: CanvasItem = null

var swapped_directions: Dictionary[StringName, StringName] = {
	&"left": &"right",
	&"right": &"left",
}

signal animation_played(animation: StringName)
signal animation_finished(animation: StringName)


func _ready() -> void:
	if has_node(^"sprite"):
		sprite = get_node(^"sprite")

	dance(true)
	animation_player.animation_finished.connect(func(anim_name: StringName) -> void:
		animation_finished.emit(anim_name)
	)


func _process(delta: float) -> void:
	if not singing:
		return

	sing_timer += delta / Conductor.instance.beat_delta
	if sing_timer * 4.0 >= sing_steps or sing_steps <= 0.0:
		dance(true)


func play_anim(anim: StringName, force: bool = false, special: bool = false) -> void:
	if (in_special_anim and not special) and animation_player.is_playing():
		return
	if not has_anim(anim):
		push_warning("Character missing animation \"%s\"!" % [anim])
		return

	in_special_anim = special
	animation = anim
	singing = animation.begins_with(&"sing_")

	if animation_player.current_animation == anim and force:
		animation_player.seek(0.0)
		animation_player.advance(0.0)
		animation_played.emit(anim)
		return

	animation_player.play(anim)
	animation_played.emit(anim)


func has_anim(anim: StringName) -> bool:
	return animation_player.has_animation(anim)


func sing(note: Note, force: bool = false) -> void:
	sing_timer = 0.0

	var direction: StringName = Note.directions[note.lane]
	if swap_sing_animations and swapped_directions.has(direction):
		direction = swapped_directions.get(direction)

	var suffixed_name: StringName = &"sing_%s%s" % [direction.to_lower(), note.sing_suffix]
	if (not note.sing_suffix.is_empty()) and has_anim(suffixed_name):
		play_anim(&"sing_%s%s" % [direction.to_lower(), note.sing_suffix], force)
	else:
		play_anim(&"sing_%s" % direction.to_lower(), force)


func sing_miss(note: Note, force: bool = false) -> void:
	sing_timer = 0.0

	var direction: StringName = Note.directions[note.lane]
	if swap_sing_animations and swapped_directions.has(direction):
			direction = swapped_directions.get(direction)

	play_anim(&"sing_%s_miss" % direction.to_lower(), force)


func dance(force: bool = false) -> void:
	if not dances:
		return
	if singing and not force:
		return
	if dance_steps.is_empty():
		return
	if dance_steps.size() > 1:
		var base: int = dance_step + 1
		if is_instance_valid(Conductor.instance):
			base = floori(Conductor.instance.beat)
		
		dance_step = wrapi(base, 0, dance_steps.size())
		play_anim(dance_steps[dance_step], force)
		return

	play_anim(dance_steps[0], force)


func set_character_material(new_material: Material) -> void:
	if is_instance_valid(sprite):
		sprite.material = new_material


func get_camera_position() -> Vector2:
	if not is_instance_valid(camera_offset):
		return Vector2.ZERO

	return camera_offset.global_position


func offset_camera_position(added: Vector2) -> void:
	if not is_instance_valid(camera_offset):
		return

	camera_offset.position += added
