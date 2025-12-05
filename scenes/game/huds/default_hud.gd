extends Control


var player_field: NoteField
var opponent_field: NoteField
var game: Game

var downscroll: bool = false:
	set(value):
		downscroll = value
		set_downscroll(value)

var centered_receptors: bool = false:
	set(value):
		centered_receptors = value
		set_centered_receptors(value)

@export var bumps: bool = false
@export var bump_amount: Vector2 = Vector2(0.03, 0.03)
@export var bump_interval: int = 4
@export var zoom_lerping: bool = true

@onready var note_fields: Node2D = %note_fields
@onready var health_bar: HealthBar = %health_bar

@onready var rating_calculator: RatingCalculator:
	get:
		if is_instance_valid(game) and is_instance_valid(game.rating_calculator):
			return game.rating_calculator
		else:
			return null
@onready var rating_container: Node2D = %rating_container
@onready var difference_label: Label = rating_container.get_node('difference_label')
@onready var rating_sprite: Sprite2D = rating_container.get_node('rating')
@onready var combo_node: Node2D = rating_container.get_node('combo')
var rating_tween: Tween

var hud_skin: HUDSkin:
	set(v):
		hud_skin = v
		rating_textures = hud_skin.get_rating_textures()

var rating_textures: Dictionary[StringName, Texture2D] = {}

signal on_setup
signal note_hit(note: Note)
signal note_miss(note: Note)
signal downscroll_changed(downscroll: bool)


func _ready() -> void:
	if is_instance_valid(Game.instance):
		game = Game.instance
		game.hud_setup.connect(setup)
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	game.conductor.beat_hit.connect(_on_beat_hit)

	if note_fields.has_node(^'player'):
		player_field = note_fields.get_node(^'player')
	if note_fields.has_node(^'opponent'):
		opponent_field = note_fields.get_node(^'opponent')
	
	rating_container.visible = false
	downscroll = Config.get_value('gameplay', 'scroll_direction') == &'down'
	centered_receptors = Config.get_value('gameplay', 'centered_receptors')


func setup() -> void:
	on_setup.emit()
	
	if is_instance_valid(hud_skin):
		combo_node.scale = hud_skin.combo_scale
		combo_node.texture_filter = hud_skin.combo_filter
		rating_sprite.scale = hud_skin.rating_scale
		rating_sprite.texture_filter = hud_skin.rating_filter
	if is_instance_valid(opponent_field):
		opponent_field.note_hit.connect(
			_on_first_opponent_note,
			CONNECT_ONE_SHOT
		)


func _on_beat_hit(beat: int) -> void:
	if not (game.playing and bumps):
		return
	if beat <= 0:
		return

	if beat % bump_interval == 0:
		scale += bump_amount


func _process(delta: float) -> void:
	if not (game.playing and zoom_lerping):
		return

	scale = scale.lerp(Vector2.ONE, delta * 3.0)


func _on_first_opponent_note(_note: Note) -> void:
	bumps = true


func _on_note_hit(note: Note) -> void:
	var health: float = game.health
	var difference: float = game.conductor.time - note.data.time
	if not player_field.takes_input:
		difference = 0.0

	game.rating_calculator.add_hit(absf(difference), note.hit_window)

	if player_field.takes_input:
		difference_label.text = '%.2fms' % [difference * 1000.0]
		difference_label.modulate = Color(0.4, 0.5, 0.8) \
				if difference < 0.0 else Color(0.8, 0.4, 0.5)
	else:
		difference_label.text = 'Botplay'
		difference_label.modulate = Color(0.6, 0.62, 0.7)

	if is_instance_valid(rating_tween) and rating_tween.is_running():
		rating_tween.kill()

	var rating: Rating = Rating.new()
	if is_instance_valid(rating_calculator):
		rating = rating_calculator.get_rating(absf(difference))
	if rating_textures.has(rating.name):
		rating_sprite.texture = rating_textures[rating.name]

	if rating.name == &'marvelous' or rating.name == &'sick':
		spawn_splash(note, player_field.skin, note.field.receptors[note.lane])

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
	var combo_spacing: float = 90.0
	if is_instance_valid(hud_skin):
		combo_spacing = hud_skin.combo_spacing
	
	combo_node.position.x = (-combo_spacing / 4.0) * (num_count - 1)
	while combo_node.get_child_count() < num_count:
		var node: Node = combo_node.get_child(0).duplicate()
		node.name = str(combo_node.get_child_count()+1)
		combo_node.add_child(node)

	for i: int in combo_node.get_child_count():
		var number: Sprite2D = combo_node.get_child(i)
		if i < num_count and is_instance_valid(hud_skin):
			number.texture = hud_skin.combo_atlas
			number.texture_filter = hud_skin.combo_filter
			number.frame = int(combo_str[i])
			number.position.x = combo_spacing * i
			number.visible = true
		else:
			number.visible = false

	note_hit.emit(note)


func _on_note_miss(note: Note) -> void:
	rating_container.visible = false
	note_miss.emit(note)


func _opponent_note_hit(note: Note) -> void:
	spawn_splash(note, opponent_field.skin, note.field.receptors[note.lane])


func set_downscroll(value: bool) -> void:
	if is_instance_valid(player_field):
		player_field.scroll_speed_modifier = -1.0 if value else 1.0
		player_field.position.y = 720.0 - 100.0 if value else 100.0
	if is_instance_valid(opponent_field):
		opponent_field.scroll_speed_modifier = -1.0 if value else 1.0
		opponent_field.position.y = 720.0 - 100.0 if value else 100.0
	
	downscroll_changed.emit(value)


func set_centered_receptors(value: bool) -> void:
	if is_instance_valid(opponent_field):
		opponent_field.visible = not value
		opponent_field.position.x = 320.0
	if is_instance_valid(player_field):
		player_field.position.x = 640.0 if value else 960.0


func spawn_splash(note: Note, skin: NoteSkin, target: Node2D) -> void:
	if not is_instance_valid(note.splash):
		return
	
	var splash: NoteSplash = note.splash.instantiate()
	splash.note = note
	if splash.use_skin and is_instance_valid(skin):
		splash.sprite_frames = skin.get_splash_frames()
		splash.scale = skin.splash_scale
		splash.texture_filter = skin.splash_filter
		splash.colors = skin.splash_colors
	note_fields.add_child(splash)

	splash.global_position = target.global_position
