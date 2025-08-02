extends Control


@export var do_countdown: bool = true
var player_field: NoteField
var opponent_field: NoteField
var game: Game

var scroll_direction: StringName = &'up':
	set(value):
		scroll_direction = value
		_set_scroll_direction(value)
var centered_receptors: bool = false:
	set(value):
		centered_receptors = value
		_set_centered_receptors(value)

@export var bump_amount: Vector2 = Vector2(0.03, 0.03)

@onready var note_fields: Node2D = %note_fields
@onready var health_bar: HealthBar = %health_bar
@onready var song_label: Label = %song_label
@onready var countdown_container: Node2D = %countdown_container

@onready var ratings_calculator: RatingsCalculator = %ratings_calculator
@onready var rating_container: Node2D = %rating_container
@onready var difference_label: Label = rating_container.get_node('difference_label')
@onready var rating_sprite: Sprite2D = rating_container.get_node('rating')
@onready var combo_node: Node2D = rating_container.get_node('combo')
var rating_tween: Tween

var pause_countdown: bool = false
var _force_countdown: bool = false
var countdown_offset: int = 0
var tracks: Tracks
var skin: HUDSkin

@onready var preloading_layer: CanvasLayer = %preloading_layer
@onready var sub_viewport_container: SubViewportContainer = %sub_viewport_container
@onready var preloading_viewport: SubViewport = %preloading_viewport


func _ready() -> void:
	if is_instance_valid(Game.instance):
		game = Game.instance
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	game.ready_post.connect(_ready_post)
	Conductor.beat_hit.connect(_on_beat_hit)
	Conductor.measure_hit.connect(_on_measure_hit)

	player_field = note_fields.get_node('player')
	opponent_field = note_fields.get_node('opponent')
	rating_container.visible = false

	if not is_instance_valid(game):
		return

	scroll_direction = Config.get_value('gameplay', 'scroll_direction')
	centered_receptors = Config.get_value('gameplay', 'centered_receptors')


func setup() -> void:
	player_field.note_hit.connect(_on_note_hit)
	player_field.note_miss.connect(_on_note_miss)

	skin = game.skin
	tracks = game.tracks
	combo_node.scale = skin.combo_scale
	combo_node.texture_filter = skin.combo_filter
	rating_sprite.scale = skin.rating_scale
	rating_sprite.texture_filter = skin.rating_filter
	countdown_container.scale = skin.countdown_scale

	song_label.text = '%s • [%s]' % [
			game.metadata.get_full_name(),
			Game.difficulty.to_upper()
	]

	# we do this because I LOVE PRELOADING SHADERS GRAHHHH
	_preload_splash(player_field.default_note_splash)
	_preload_splash(opponent_field.default_note_splash)


func countdown_resume() -> void:
	if _force_countdown:
		return

	Conductor.target_audio.seek(
		maxf(Conductor.raw_time - (4.0 * Conductor.beat_delta), 0.0)
	)
	countdown_offset = -floori(Conductor.beat) - 1
	_force_countdown = true
	pause_countdown = false

	Conductor.target_audio.volume_linear = 0.0
	create_tween().tween_property(
		Conductor.target_audio,
		^'volume_linear',
		1.0,
		4.0 * Conductor.beat_delta
	)


func _ready_post() -> void:
	if not do_countdown:
		Conductor.raw_time = 0.0


func _on_beat_hit(beat: int) -> void:
	if (not do_countdown) and not _force_countdown:
		return
	if (beat >= 0 or game.song_started) and not _force_countdown:
		return

	if pause_countdown:
		Conductor.raw_time = -5.0 * Conductor.beat_delta
		return

	# countdown lol
	beat += countdown_offset
	if beat >= 0 and _force_countdown:
		_force_countdown = false
		return
	var index: int = clampi(4 - absi(beat), 0, 3)
	_display_countdown_sprite(index)
	_play_countdown_sound(index)


func _on_measure_hit(_measure: int) -> void:
	if not (game.playing and game.camera_bumps):
		return

	scale += bump_amount


func _process(delta: float) -> void:
	if not (game.playing and game.camera_bumps):
		return
	if (
		is_instance_valid(preloading_viewport)
		and preloading_viewport.get_child_count() == 0
	):
		preloading_layer.queue_free()

	scale = scale.lerp(Vector2.ONE, delta * 3.0)


func _on_note_hit(note: Note) -> void:
	var health: float = game.health
	var difference: float = Conductor.time - note.data.time
	if not player_field.takes_input:
		difference = 0.0

	game.accuracy_calculator.record_hit(absf(difference))

	if player_field.takes_input:
		difference_label.text = '%.2fms' % [difference * 1000.0]
		difference_label.modulate = Color(0.4, 0.5, 0.8) \
				if difference < 0.0 else Color(0.8, 0.4, 0.5)
	else:
		difference_label.text = 'Botplay'
		difference_label.modulate = Color(0.6, 0.62, 0.7)

	if is_instance_valid(rating_tween) and rating_tween.is_running():
		rating_tween.kill()

	var rating: Rating = ratings_calculator.get_rating(absf(difference * 1000.0))
	match rating.name:
		&'marvelous':
			rating_sprite.texture = skin.marvelous
		&'sick':
			rating_sprite.texture = skin.sick
		&'good':
			rating_sprite.texture = skin.good
		&'bad':
			rating_sprite.texture = skin.bad
		&'shit':
			rating_sprite.texture = skin.shit

	if is_instance_valid(note.splash) and \
			(rating.name == &'marvelous' or rating.name == &'sick'):
		var splash: AnimatedSprite = note.splash.instantiate()
		splash.note = note
		var player_skin: NoteSkin = player_field.skin
		if splash.use_skin and is_instance_valid(player_skin):
			splash.sprite_frames = player_skin.splash_frames
			splash.scale = player_skin.splash_scale
			splash.texture_filter = player_skin.splash_filter
		add_child(splash)

		splash.global_position = note.field.receptors[note.lane].global_position

	rating_container.visible = true
	rating_container.modulate.a = 1.0
	rating_container.scale = Vector2(1.1, 1.1)
	rating_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rating_tween.tween_property(rating_container, 'scale', Vector2.ONE, 0.15)
	rating_tween.tween_property(rating_container, 'modulate:a', 0.0, 0.25).set_delay(0.25)
	rating_tween.tween_callback(func() -> void:
		rating_container.visible = false).set_delay(0.5)

	game.health = clampf(health + rating.health, 0.0, 100.0)
	game.score += rating.score

	var combo_str: String = str(game.combo).pad_zeros(3)
	var num_count: int = combo_str.length()
	combo_node.position.x = (-skin.combo_spacing / 4.0) * (num_count - 1)

	while combo_node.get_child_count() < num_count:
		var node: Node = combo_node.get_child(0).duplicate()
		node.name = str(combo_node.get_child_count()+1)
		combo_node.add_child(node)

	for i: int in combo_node.get_child_count():
		var number: Sprite2D = combo_node.get_child(i)
		if i < num_count:
			number.texture = skin.combo_atlas
			number.texture_filter = skin.combo_filter
			number.frame = int(combo_str[i])
			number.position.x = skin.combo_spacing * i
			number.visible = true
		else:
			number.visible = false

	health_bar.update_score_label()


func _on_note_miss(_note: Note) -> void:
	rating_container.visible = false
	health_bar.update_score_label()


func _display_countdown_sprite(index: int) -> void:
	# Don't display things that don't exist.
	if not is_instance_valid(skin.countdown_textures[index]):
		return

	var sprite: Sprite2D = Sprite2D.new()
	sprite.scale = Vector2(1.05, 1.05)
	sprite.texture = skin.countdown_textures[index]
	sprite.texture_filter = skin.rating_filter
	countdown_container.add_child(sprite)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(sprite, ^'modulate:a', 0.0, Conductor.beat_delta)
	tween.tween_property(sprite, ^'scale', Vector2.ONE, Conductor.beat_delta)
	tween.tween_callback(sprite.queue_free).set_delay(Conductor.beat_delta)


func _play_countdown_sound(index: int) -> void:
	# Don't play things that don't exist.
	if not is_instance_valid(skin.countdown_sounds[index]):
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = skin.countdown_sounds[index]
	player.bus = &'SFX'
	player.finished.connect(player.queue_free)
	countdown_container.add_child(player)
	player.play()


func _set_scroll_direction(value: StringName) -> void:
	if value != &'up' and value != &'down':
		printerr('A scroll direction of %s is not supported at this time.' % [value])
		return

	player_field.scroll_speed_modifier = 1.0 if value == &'up' else -1.0
	opponent_field.scroll_speed_modifier = player_field.scroll_speed_modifier

	match value:
		&'up':
			player_field.position.y = 100.0
			opponent_field.position.y = 100.0
			health_bar.position.y = 720.0 - 80.0
			song_label.position.y = 12.0
		&'down':
			player_field.position.y = 720.0 - 100.0
			opponent_field.position.y = 720.0 - 100.0
			health_bar.position.y = 80.0
			song_label.position.y = 720.0 - 28.0


func _set_centered_receptors(value: bool) -> void:
	opponent_field.visible = not value
	if value:
		player_field.position.x = 640.0
	else:
		player_field.position.x = 960.0
		opponent_field.position.x = 320.0


func _preload_splash(scene: PackedScene) -> void:
	if not is_instance_valid(scene):
		return
	if not is_instance_valid(preloading_viewport):
		return

	var splash: AnimatedSprite = scene.instantiate()
	preloading_viewport.add_child(splash)
