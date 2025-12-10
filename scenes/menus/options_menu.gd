class_name OptionsMenu extends Node2D


const default_target_scene: String = 'res://scenes/menus/main_menu.tscn'
static var target_scene: String = default_target_scene

@onready var interface: Control = %interface
@onready var categories: HBoxContainer = %categories
@onready var section: Node2D = %section
@onready var options_label: AnimatedSprite2D = %options_label
@onready var section_label: Alphabet = %section_label
@onready var conductor: Conductor = %conductor

var section_tween: Tween

var selected: int = 0
var active: bool = true


func _ready() -> void:
	var music_player: AudioStreamPlayer = GlobalAudio.music
	music_player.stream = load('uid://ddoyqrhrcjw1j')
	music_player.play()
	conductor.reset()
	conductor.tempo = 137.0
	conductor.target_audio = music_player
	conductor.beat_hit.connect(_on_beat_hit)
	change_selection()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action(&'ui_left') or event.is_action(&'ui_right'):
		change_selection(roundi(Input.get_axis(&'ui_left', &'ui_right')))
	if event.is_action(&'ui_up') or event.is_action(&'ui_down'):
		change_selection(roundi(Input.get_axis(&'ui_up', &'ui_down')))
	if event.is_action(&'ui_accept'):
		select_current()
	if event.is_action(&'ui_cancel'):
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		SceneManager.switch_to(load(target_scene))
		target_scene = default_target_scene


func change_selection(amount: int = 0) -> void:
	GlobalAudio.get_player('MENU/SCROLL').play()
	selected = wrapi(selected + amount, 0, categories.get_child_count())

	section_label.text = categories.get_child(selected).name.to_upper()
	section_label.position.y = 40.0
	section_label.modulate.a = 0.75

	if is_instance_valid(section_tween) and section_tween.is_running():
		section_tween.kill()
	section_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_parallel()
	section_tween.tween_property(section_label, ^'position:y', 48.0, 0.5)
	section_tween.tween_property(section_label, ^'modulate:a', 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)

	for i: int in categories.get_child_count():
		var child: Category = categories.get_child(i)
		if i == selected:
			child.target_alpha = 1.0
			child.target_scale = 1.0
		else:
			child.target_alpha = 0.6
			child.target_scale = 0.8


func deselect_current() -> void:
	active = true
	GlobalAudio.get_player('MENU/CANCEL').play()
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(interface, ^'position:x', 0.0, 0.5)
	tween.tween_property(section, ^'position:x', 1920.0, 0.5)
	var children: Array[Node] = section.get_children()
	tween.tween_callback(GameUtils.free_from_array.bind(children)).set_delay(0.5)


func select_current() -> void:
	active = false
	GlobalAudio.get_player('MENU/CONFIRM').play()

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(interface, ^'position:x', -1280.0, 0.5)
	tween.tween_property(section, ^'position:x', 640.0, 0.5)

	var current_selected: Category = categories.get_child(selected)
	var options_section: BaseOptionsSection = current_selected.category.instantiate()
	section.add_child(options_section)


func _process(delta: float) -> void:
	options_label.scale = options_label.scale.lerp(Vector2(0.6, 0.6), delta * 4.5)


func _on_beat_hit(_beat: int) -> void:
	options_label.scale = Vector2(0.65, 0.65)


func _exit_tree() -> void:
	GlobalAudio.music.stream = load('uid://dergcpn8f5cju')
	GlobalAudio.music.play()
