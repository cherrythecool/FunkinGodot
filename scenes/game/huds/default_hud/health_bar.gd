class_name HealthBar extends Node2D


@onready var bar: ProgressBar = $bar
@onready var icons: Node2D = $icons
@onready var score_label: Label = $score_label

var player_icon: Sprite2D = null
var player_color: Color:
	set(value):
		player_color = value
		bar.get('theme_override_styles/fill').bg_color = player_color

var opponent_icon: Sprite2D = null
var opponent_color: Color:
	set(value):
		opponent_color = value
		bar.get('theme_override_styles/background').bg_color = opponent_color
var rank: StringName = &'N/A'

var game: Game


func _ready() -> void:
	if not is_instance_valid(Game.instance):
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	game = Game.instance


func _process(delta: float) -> void:
	bar.value = lerpf(bar.value, game.health, GameUtils.lerp_weight(delta, 5.0))
	icons.scale = Vector2(1.2, 1.2).lerp(Vector2.ONE, icon_lerp())
	position_icons(bar.value)

	var player_frames: int = player_icon.hframes * player_icon.vframes
	var opponent_frames: int = opponent_icon.hframes * opponent_icon.vframes

	if bar.value >= 80.0:
		player_icon.frame = 2 if player_frames >= 3 else 0
		opponent_icon.frame = 1 if opponent_frames >= 2 else 0
	elif bar.value <= 20.0:
		player_icon.frame = 1 if player_frames >= 2 else 0
		opponent_icon.frame = 2 if opponent_frames >= 3 else 0
	else:
		player_icon.frame = 0
		opponent_icon.frame = 0


func update_score_label() -> void:
	score_label.text = 'Score:%d • Misses:%d • Accuracy:%.3f%% (%s)' % [
		game.score,
		game.misses,
		GameUtils.truncate_float_to(game.accuracy, 3),
		game.rank,
	]


func reload_icons() -> void:
	if is_instance_valid(player_icon) and is_instance_valid(opponent_icon):
		player_icon.queue_free()
		opponent_icon.queue_free()

	reload_icon_colors()

	player_icon = Icon.create_sprite(Game.instance.player.icon)
	player_icon.position.x = 50.0
	icons.add_child(player_icon)
	player_icon.flip_h = true

	opponent_icon = Icon.create_sprite(Game.instance.opponent.icon)
	opponent_icon.position.x = -50.0
	icons.add_child(opponent_icon)


func reload_icon_colors() -> void:
	player_color = Game.instance.player.icon.color
	opponent_color = Game.instance.opponent.icon.color


# ease out sine
func icon_ease(x: float) -> float:
	return sin((x * PI) / 2.0)


func icon_lerp() -> float:
	return icon_ease(game.conductor.beat - floorf(game.conductor.beat))


func position_icons(health: float) -> void:
	icons.position.x = 320.0 - (health * 6.4)


func _on_hud_downscroll_changed(downscroll: bool) -> void:
	position.y = 80.0 if downscroll else 720.0 - 80.0


func _on_hud_note_hit(_note: Note) -> void:
	update_score_label()


func _on_hud_note_miss(_note: Note) -> void:
	update_score_label()


func _on_hud_setup() -> void:
	reload_icons()
