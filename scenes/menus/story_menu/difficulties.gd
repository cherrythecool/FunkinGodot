extends Control


@onready var weeks: StoryModeWeeks = %weeks
@onready var high_score: Label = %high_score
@onready var left_arrow: AnimatedSprite = $left_arrow
@onready var right_arrow: AnimatedSprite = $right_arrow
@onready var difficulty: Sprite2D = $difficulty
@onready var animated_difficulty: AnimatedSprite = difficulty.get_node('animated')

static var selected: int = 1
var difficulties: PackedStringArray = []
var tween: Tween = null
var target_score: int = 0
var lerp_score: float = 0.0:
	set(v):
		lerp_score = v
		high_score.text = 'High Score: %d' % [roundi(lerp_score)]


func _process(delta: float) -> void:
	lerp_score = lerpf(lerp_score, float(target_score), delta * 6.0)


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action('ui_left'):
		left_arrow.play(&'leftConfirm' if event.is_pressed() else &'leftIdle')
	if event.is_action('ui_right'):
		right_arrow.play(&'rightConfirm' if event.is_pressed() else &'rightIdle')


func change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, difficulties.size())

	difficulty.visible = not difficulties.is_empty()
	if difficulties.is_empty():
		return

	_reload_difficulty_sprite()
	_tween_difficulty_sprite()
	_calculate_high_score()


func _reload_difficulty_sprite() -> void:
	## TODO: maybe rework this to be a dictionary with textures instead lol
	var path: String = 'res://assets/menus/story_menu/difficulties/%s' \
			% difficulties[selected]
	var is_animated: bool = ResourceLoader.exists('%s.res' % path)
	if is_animated:
		animated_difficulty.visible = true
		animated_difficulty.sprite_frames = load('%s.res' % path)
		animated_difficulty.play(&'idle')
		difficulty.self_modulate.a = 0.0
	else:
		animated_difficulty.visible = false
		difficulty.self_modulate.a = 1.0
		difficulty.texture = load('%s.png' % path)


func _tween_difficulty_sprite() -> void:
	difficulty.modulate.a = 0.0
	difficulty.position.y = 132.0 - 25.0
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel()
	tween.tween_property(difficulty, 'modulate:a', 1.0, 0.07)
	tween.tween_property(difficulty, 'position:y', 132.0, 0.07)


func _calculate_high_score() -> void:
	var difficulty: String = difficulties[selected]
	var week: StoryWeekNode = weeks.get_child(StoryModeWeeks.selected_static)
	var suffix: String = week.difficulty_suffixes.mapping.get(difficulty, '')
	target_score = 0

	for raw_song in week.songs:
		var song := raw_song + suffix
		if not Scores.has_score(song, difficulty):
			high_score.text = 'High Score: N/A'
			break
		target_score += Scores.get_score(song, difficulty).get('score', 0)
