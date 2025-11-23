class_name Gameover extends Node2D


static var character_position: Vector2 = Vector2.ZERO
static var character_path: String = "res://scenes/game/characters/bf_dead.tscn"

@onready var camera: GameCamera2D = %camera_2d
@onready var initial_focus_timer: Timer = %initial_focus_timer
@onready var fade_out_delay: Timer = %fade_out_delay

@onready var conductor: Conductor = %conductor
@onready var music_player: AudioStreamPlayer = %music
@onready var on_death: AudioStreamPlayer = %on_death
@onready var retry: AudioStreamPlayer = %retry

@onready var secret: CanvasLayer = %secret

var character: Character
var active: bool = true


func _ready() -> void:
	randomize()
	active = true

	var player: VideoStreamPlayer = secret.get_node(^"player")
	var value: int = randi_range(1, 1000)
	if value == 127:
		active = false
		player.stream = load("uid://6jxbt142o25i")
		player.play()
		return
	elif value == 67:
		active = false
		player.stream = load("uid://db4cvq6qsh27")
		player.play()
		player.volume = 1.0
		return
	else:
		secret.queue_free()

	conductor.reset()
	conductor.target_audio = music_player
	initial_focus_timer.start()

	if not ResourceLoader.exists(character_path):
		character_path = "uid://w4v0gymuehdt"
	character = load(character_path).instantiate()

	if is_instance_valid(character.gameover_assets):
		var assets: GameoverAssets = character.gameover_assets
		if is_instance_valid(assets.on_death):
			on_death.stream = assets.on_death
		if is_instance_valid(assets.looping_music):
			music_player.stream = assets.looping_music
		if is_instance_valid(assets.retry):
			retry.stream = assets.retry

	add_child(character)
	character.global_position = character_position
	if character.has_anim(&"death"):
		character.play_anim(&"death")
		character.animation_finished.connect(_on_animation_finished)
		on_death.play()
	else:
		on_death.finished.connect(_on_animation_finished.bind(&"death"))
		on_death.play()


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if not active:
		return

	if event.is_action(&"ui_cancel"):
		active = false
		GlobalAudio.get_player(^"MENU/CANCEL").play()
		GameCamera2D.reset_persistent_values()
		
		match Game.mode:
			Game.PlayMode.FREEPLAY:
				SceneManager.switch_to(load(MainMenu.freeplay_scene))
			Game.PlayMode.STORY:
				SceneManager.switch_to(load("uid://dcf86iwg6mn3d"))
			_:
				SceneManager.switch_to(load("uid://cxk008iuw4n7u"))
	
	if event.is_action(&"ui_accept"):
		active = false
		character.play_anim(&"retry")
		music_player.stop()
		retry.play()
		fade_out_delay.start()


func _on_animation_finished(animation: StringName) -> void:
	match animation:
		&"death":
			character.play_anim(&"loop")
			music_player.play()


func _on_initial_focus_timer_timeout() -> void:
	camera.position_lerps = true
	camera.position_target = character.get_camera_position()


func _on_fade_out_timer_timeout() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(character, ^"modulate:a", 0.0, 2.0)
	tween.tween_callback(func() -> void:
		SceneManager.switch_to(load("uid://da8mu3oqto3qq"))
	)
