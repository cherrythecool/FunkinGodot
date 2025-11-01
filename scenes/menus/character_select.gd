extends Node2D


@onready var CHARACTER_SELECT: AudioStream = load('uid://b234a5vj6k6')

@onready var character_selector: Node2D = %character_selector
@onready var dipshit_blur: AnimatedSprite = %dipshit_blur
@onready var dipshit_backing: AnimatedSprite = %dipshit_backing
@onready var choose_dipshit: Sprite2D = %choose_dipshit

@onready var spectator: AnimateSymbol = %spectator
var spectator_anim: AnimationPlayer

@onready var player: AnimateSymbol = %player
var player_anim: AnimationPlayer

@onready var speakers: AnimateSymbol = $speakers/sprite

@onready var music: AudioStreamPlayer = %music
@onready var select: AudioStreamPlayer = %select
@onready var confirm: AudioStreamPlayer = %confirm
@onready var deny: AudioStreamPlayer = %deny

@onready var characters: Node2D = %characters
@onready var title: Sprite2D = %title
@onready var atlas_characters: Node2D = %atlas_characters

@onready var selector: AnimatedSprite = %selector
static var selected_x: int = 1
static var selected_y: int = 1
var locked: bool = false

var dipshit_tween: Tween


func _ready() -> void:
	GlobalAudio.music.stop()

	Conductor.reset()
	Conductor.target_audio = music
	Conductor.tempo = 90.0
	Conductor.beat_hit.connect(_on_beat_hit)
	music.stream = CHARACTER_SELECT
	music.play()

	dipshit_tween = create_tween().set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	character_selector.position.y += 220.0
	dipshit_tween.tween_property(character_selector, ^'position:y',
			character_selector.position.y - 220.0, 1.2)

	dipshit_backing.position.y -= 10.0
	dipshit_tween.tween_property(dipshit_backing, ^'position:y',
			dipshit_backing.position.y + 10.0, 1.1)

	choose_dipshit.position.y -= 20.0
	dipshit_tween.tween_property(choose_dipshit, ^'position:y',
			choose_dipshit.position.y + 20.0, 1.0)

	spectator_anim = spectator.get_node(^'animation_player')
	spectator_anim.play(&'enter')
	player_anim = player.get_node(^'animation_player')
	player_anim.play(&'enter')

	_update_selection(false)


func _process(delta: float) -> void:
	for i: int in characters.get_child_count():
		var icon: Node2D = characters.get_child(i)
		if i == selected_x + (selected_y * 3):
			selector.global_position = selector.global_position.lerp(icon.global_position, delta * 12.0)
			icon.scale = icon.scale.lerp(Vector2.ONE * 1.15, delta * 9.0)
		else:
			icon.scale = icon.scale.lerp(Vector2.ONE, delta * 9.0)


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return

	if event.is_action(&'ui_cancel'):
		if locked:
			locked = false
			deny.play()
			selector.play(&'denied')
			player_anim.play(&'cancel')
			spectator_anim.play(&'cancel')
			confirm.stop()

			var index: int = selected_x + (selected_y * 3)
			# TODO: make this a script or smth so better customization
			var icon: AnimatedSprite = characters.get_child(index)
			icon.playing = false
			icon.frame = 0

			await spectator_anim.animation_finished

			selector.play(&'idle')
		else:
			SceneManager.switch_to(load('res://scenes/menus/main_menu.tscn'))
	if event.is_action(&'ui_accept') and not locked:
		locked = true

		var index: int = selected_x + (selected_y * 3)
		# TODO: make this a script or smth so better customization
		var icon: AnimatedSprite = characters.get_child(index)
		match icon.editor_description:
			'bf':
				confirm.play()
				selector.play(&'confirm')
				player_anim.play(&'confirm')
				spectator_anim.play(&'confirm')

				icon.playing = true
				await confirm.finished
				FreeplayMenu.index = 0
				FreeplayMenu.difficulty_index = 0
				MainMenu.freeplay_scene = 'res://scenes/menus/freeplay_menu.tscn'
				SceneManager.switch_to(load(MainMenu.freeplay_scene))
			'pico':
				confirm.play()
				player_anim.play(&'confirm')
				spectator_anim.play(&'confirm')
				selector.play(&'confirm')

				icon.playing = true
				await confirm.finished
				FreeplayMenu.index = 0
				FreeplayMenu.difficulty_index = 0
				MainMenu.freeplay_scene = 'res://scenes/menus/freeplay_menu_pico.tscn'
				SceneManager.switch_to(load(MainMenu.freeplay_scene))
			_:
				locked = false
				selector.play(&'denied')
				deny.play()

	# TODO: make this cleaner
	if locked:
		return
	if event.is_action(&'ui_left'):
		selected_x = wrapi(selected_x - 1, 0, 3)
		_update_selection()
	if event.is_action(&'ui_right'):
		selected_x = wrapi(selected_x + 1, 0, 3)
		_update_selection()
	if event.is_action(&'ui_up'):
		selected_y = wrapi(selected_y - 1, 0, 3)
		_update_selection()
	if event.is_action(&'ui_down'):
		selected_y = wrapi(selected_y + 1, 0, 3)
		_update_selection()


func _update_selection(sound: bool = true) -> void:
	selector.play(&'idle')
	if sound:
		select.play()

	var index: int = selected_x + (selected_y * 3)
	# TODO: make this a script or smth so better customization
	var icon: AnimatedSprite = characters.get_child(index)
	match icon.editor_description:
		'bf':
			_load_characters('uid://d3uuros7qs2p', 'uid://dh0j85o8ohuon', load('uid://86qag6byq5lj'))
		'pico':
			_load_characters('uid://c6to8sv86340c', 'uid://b6oapcexvu5n', load('uid://dwv1twuy3tllg'))
		_:
			_load_characters('uid://bydgpm6a02kid', 'uid://bydgpm6a02kid', load('uid://ncq3u01qhoh8'))


func _load_characters(player_path: String, spectator_path: String, logo: Texture2D) -> void:
	title.texture = logo
	spectator.queue_free()
	player.queue_free()

	var spectator_scene: PackedScene = load(spectator_path)
	var spectator_node: Node = spectator_scene.instantiate()
	atlas_characters.add_child(spectator_node)
	spectator = spectator_node

	var player_scene: PackedScene = load(player_path)
	var player_node: Node = player_scene.instantiate()
	atlas_characters.add_child(player_node)
	player = player_node

	spectator_anim = spectator.get_node(^'animation_player')
	spectator_anim.play(&'enter')
	player_anim = player.get_node(^'animation_player')
	player_anim.play(&'enter')


func _on_beat_hit(beat: int) -> void:
	speakers.frame = 0
	speakers.playing = true

	if not locked:
		if (
			player_anim.current_animation == &'cancel'
			or spectator_anim.current_animation == &'cancel'
		):
			return

		if player_anim.has_animation(&'idle'):
			player_anim.play(&'idle')
		if spectator_anim.has_animation(&'dance_left'):
			spectator_anim.play(&'dance_left' if beat % 2 == 0 else &'dance_right')


func _on_music_finished() -> void:
	if music.stream != CHARACTER_SELECT:
		music.stream = CHARACTER_SELECT

	Conductor.reset()
	Conductor.target_audio = music
	Conductor.tempo = 90.0
	music.play()
