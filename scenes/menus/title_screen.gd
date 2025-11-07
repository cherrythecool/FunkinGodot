class_name TitleScreen extends Node2D


static var first_open: bool = true

@export var swag_material: ShaderMaterial

@onready var conductor: Conductor = %conductor

@onready var post_intro: Node2D = $post_intro
@onready var girlfriend_animation: AnimationPlayer = $post_intro/girlfriend/animation_player
@onready var logo_sprite: AnimatedSprite = $post_intro/logo/sprite
@onready var enter_animation: AnimationPlayer = $post_intro/enter/animation_player
@onready var flash: ColorRect = $flash

@onready var intro_sequence: Node2D = $intro_sequence
@onready var intro_animation: AnimationPlayer = $intro_sequence/animation_player
@onready var alphabet: Alphabet = %alphabet
var introing: bool = false

var dance_left: bool = false
var active: bool = true

var random_lines: Array = ['test1', 'test2']
var random_line_index: int = 0
var tween: Tween
var last_music_time: float = 0.0


func _ready() -> void:
	if Config.first_launch:
		Config.first_launch = false
		SceneManager.switch_to(load('res://scenes/menus/first_launch.tscn'), false)
		return

	enter_animation.play('loop')

	conductor.tempo = 102.0
	var music_player: AudioStreamPlayer = GlobalAudio.music
	if not music_player.playing:
		conductor.reset()
		music_player.play()
		last_music_time = music_player.get_playback_position()
		conductor.target_audio = music_player

	if first_open:
		_start_intro()
	else:
		intro_sequence.queue_free()
		post_intro.visible = true

	first_open = false
	conductor.beat_hit.connect(_on_beat_hit)
	_on_beat_hit(0)


func _process(delta: float) -> void:
	if not is_instance_valid(swag_material):
		return

	var swag_axis: float = Input.get_axis('ui_left', 'ui_right')
	swag_material.set_shader_parameter('value',
			swag_material.get_shader_parameter('value') + delta * 0.1 * swag_axis)


func _on_beat_hit(beat: int) -> void:
	dance_left = not dance_left
	girlfriend_animation.play('dance_left' if dance_left else 'dance_right')
	logo_sprite.play('bump')
	logo_sprite.frame = 0

	if introing:
		if float(beat) >= intro_animation.current_animation_length:
			_skip_intro()
			return

		var previous: String = alphabet.text
		intro_animation.seek(float(beat), true)
		alphabet.horizontal_alignment = "Center"
		if alphabet.text == '!random':
			alphabet.text = previous
			_add_random_line()
		if alphabet.text == '!randomall':
			alphabet.text = previous
			while random_line_index <= random_lines.size() - 1 and random_line_index > 0:
				_add_random_line()
			if alphabet.text.begins_with("#include"):
				alphabet.horizontal_alignment = "Left"
			
		if alphabet.text == '!keep':
			alphabet.text = previous


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action(&'ui_cancel') and not DisplayServer.is_touchscreen_available():
		get_tree().quit()
	if event.is_action(&'ui_accept'):
		if introing:
			_skip_intro()
			return

		active = false
		GlobalAudio.get_player('MENU/CONFIRM').play()

		if Config.get_value('accessibility', 'flashing_lights'):
			enter_animation.play('press')
			flash.color = Color.WHITE
		else:
			flash.color = Color.TRANSPARENT
			enter_animation.play('press')
			enter_animation.speed_scale = 0.0

		if is_instance_valid(tween) and tween.is_running():
			tween.kill()

		tween = create_tween()
		tween.tween_property(flash, 'color:a', 0.0, 1.0)
		tween.tween_callback(SceneManager.switch_to.bind(load('res://scenes/menus/main_menu.tscn')))


func _start_intro() -> void:
	introing = true
	intro_animation.play(&'intro')

	var lines: String = FileAccess.get_file_as_string('res://assets/intro_messages.txt')
	lines = lines.strip_edges()
	var lines_array: PackedStringArray = lines.split('\n', false)
	if lines_array.is_empty():
		random_lines = ["hey!", "why did...", "you remove..!", "intro_messages.txt", "??!"]
		return
	
	var index: int = randi_range(0, lines_array.size() - 1)
	random_lines = Array(lines_array[index].split('--'))


func _add_random_line() -> void:
	alphabet.text += random_lines[random_line_index] + '\n'
	random_line_index = wrapi(random_line_index + 1, 0, random_lines.size())


func _skip_intro() -> void:
	introing = false
	intro_sequence.queue_free()
	post_intro.visible = true
	flash.color = Color.WHITE

	tween = create_tween()
	tween.tween_property(flash, 'color:a', 0.0, 1.0)
