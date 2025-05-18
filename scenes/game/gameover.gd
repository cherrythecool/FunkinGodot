class_name Gameover extends Node2D


static var character_position: Vector2 = Vector2.ZERO
static var character_path: String = 'res://scenes/game/assets/characters/face.tscn'
static var camera_zoom: Vector2 = Vector2.ONE
static var camera_position: Vector2 = Vector2.ZERO

@onready var camera: Camera2D = %camera
@onready var music_player: AudioStreamPlayer = %music
@onready var on_death: AudioStreamPlayer = %on_death
@onready var retry: AudioStreamPlayer = %retry
@onready var secret: CanvasLayer = $secret

var character: Character
var active: bool = true


func _ready() -> void:
	randomize()
	active = true

	var value: int = randi_range(1, 1000)
	if value == 273:
		active = false
		secret.get_node(^'player').stream = load('uid://6jxbt142o25i')
		secret.get_node(^'player').play()
		return
	else:
		secret.queue_free()

	Conductor.reset()
	Conductor.tempo = 100.0
	Conductor.target_audio = music_player

	camera.zoom = camera_zoom
	camera.global_position = camera_position
	camera.position_smoothing_enabled = false
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		camera.position_smoothing_enabled = true
		camera.position = character.position + character._camera_offset.position
	)

	character = load(character_path).instantiate()

	if is_instance_valid(character.gameover_assets):
		var assets: GameoverAssets = character.gameover_assets
		if is_instance_valid(assets.on_death):
			on_death.stream = assets.on_death
		if is_instance_valid(assets.looping_music):
			music_player.stream = assets.looping_music
			Conductor.tempo = assets.music_bpm # hehe
		if is_instance_valid(assets.retry):
			retry.stream = assets.retry

	add_child(character)
	character.global_position = character_position
	if character.has_anim(&'death'):
		character.play_anim(&'death')
		character.animation_finished.connect(_on_animation_finished)
		on_death.play()
	else:
		on_death.play()
		await on_death.finished
		_on_animation_finished(&'death')


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if not active:
		# prevent f5'ing during the easter egg
		if event.is_action('menu_reload'):
			get_viewport().set_input_as_handled()
		return

	if event.is_action('ui_cancel'):
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		match Game.mode:
			Game.PlayMode.FREEPLAY:
				SceneManager.switch_to(MainMenu.freeplay_scene)
			Game.PlayMode.STORY:
				SceneManager.switch_to('uid://dcf86iwg6mn3d')
			_:
				SceneManager.switch_to('uid://cxk008iuw4n7u')
	if event.is_action('ui_accept'):
		active = false
		character.play_anim(&'retry')
		music_player.stop()
		retry.play()
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			var tween: Tween = create_tween()
			tween.tween_property(self, 'modulate:a', 0.0, 2.0)
			tween.tween_callback(func() -> void:
				SceneManager.switch_to('uid://da8mu3oqto3qq')
			)
		)


func _on_animation_finished(animation: StringName) -> void:
	match animation:
		&'death':
			character.play_anim(&'loop')
			music_player.play()
