extends CanvasLayer


@onready var options: Node2D = %options
@onready var root: Control = $root
@onready var music: AudioStreamPlayer = $music

@onready var song_name: Alphabet = %song_name
@onready var play_type: Alphabet = %play_type

var active: bool = true
var selected: int = 0


func _ready() -> void:
	Engine.time_scale = 1.0
	_change_selection()

	root.modulate.a = 0.5
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(root, ^"modulate:a", 1.0, 0.5)

	create_tween().tween_property(music, ^"volume_linear", 0.9, 2.0).set_delay(0.5)
	if not is_instance_valid(Game.instance):
		return
	if is_instance_valid(Game.instance.skin) and \
			is_instance_valid(Game.instance.skin.pause_music):
		music.stream = Game.instance.skin.pause_music
		music.play()

	var keys: Array = Game.PlayMode.keys()
	song_name.text = "%s\n(%s)" % [Game.instance.metadata.get_full_name(),
			Game.difficulty.to_upper(),]
	if song_name.size.x > Global.game_size.x:
		song_name.scale = Vector2.ONE * (Global.game_size.x / song_name.size.x * 0.9)
	song_name.position.x = Global.game_size.x - \
			(float(song_name.size.x) * song_name.scale.x) - 16.0
	play_type.text = keys[Game.mode].to_upper()
	play_type.position = Global.game_size - (Vector2(play_type.size) * 0.75) - \
			Vector2(16.0, 16.0)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not active:
		return
	if not event.is_pressed():
		return
	if event.is_echo():
		return

	if event.is_action(&"ui_down") or event.is_action(&"ui_up"):
		_change_selection(roundi(Input.get_axis("ui_up", "ui_down")))
	if event.is_action(&"ui_accept"):
		for option: ListedAlphabet in options.get_children():
			if option.target_y != 0:
				continue
			var type: StringName = option.name.to_lower()
			match type:
				&"resume":
					_close()
				&"restart":
					_close()
					get_tree().reload_current_scene()
				&"options":
					OptionsMenu.target_scene = "res://scenes/game/game.tscn"
					_close()
					SceneManager.switch_to(load("res://scenes/menus/options_menu.tscn"))
				&"quit":
					_close()
					Game.instance.finish_song(true)
				_:
					printerr("Pause Option %s unimplemented." % type)


func _change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, options.get_child_count())

	if amount != 0:
		GlobalAudio.get_player("MENU/SCROLL").play()
	for i: int in options.get_child_count():
		var option: ListedAlphabet = options.get_child(i)
		option.target_y = i - selected
		option.modulate.a = 1.0 if option.target_y == 0 else 0.6


func _close() -> void:
	queue_free()
	get_viewport().set_input_as_handled()
	active = false
	visible = false
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_INHERIT
	
	if is_instance_valid(Conductor.instance):
		Engine.time_scale = Conductor.instance.rate
	if is_instance_valid(Game.instance):
		Game.instance.conductor.active = true
		Game.instance.unpaused.emit()
