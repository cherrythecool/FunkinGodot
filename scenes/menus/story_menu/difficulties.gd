extends Control


static var selected: int = 1

@export var textures: Dictionary[StringName, Texture2D] = {}
@export var sprite_frames: Dictionary[StringName, SpriteFrames] = {}

@onready var weeks: StoryModeWeeks = %weeks
@onready var high_score: Label = %high_score
@onready var left_arrow: AnimatedSprite = $left_arrow
@onready var right_arrow: AnimatedSprite = $right_arrow
@onready var difficulty_sprite: Sprite2D = $difficulty
@onready var animated_difficulty: AnimatedSprite = difficulty_sprite.get_node('animated')

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
		
		if event.is_pressed():
			change_selection(-1)
	if event.is_action('ui_right'):
		right_arrow.play(&'rightConfirm' if event.is_pressed() else &'rightIdle')
		
		if event.is_pressed():
			change_selection(1)


func change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, difficulties.size())

	difficulty_sprite.visible = not difficulties.is_empty()
	if difficulties.is_empty():
		return

	reload_difficulty_sprite()
	tween_difficulty_sprite()
	calculate_high_score()


func reload_difficulty_sprite() -> void:
	var difficulty: String = difficulties[selected]
	if sprite_frames.has(difficulty):
		animated_difficulty.visible = true
		animated_difficulty.sprite_frames = sprite_frames.get(difficulty)
		animated_difficulty.play(&'idle')
		difficulty_sprite.self_modulate.a = 0.0
	elif textures.has(difficulty):
		animated_difficulty.visible = false
		difficulty_sprite.self_modulate.a = 1.0
		difficulty_sprite.texture = textures.get(difficulty)


func tween_difficulty_sprite() -> void:
	difficulty_sprite.modulate.a = 0.5
	difficulty_sprite.position.y = 132.0 - 25.0
	difficulty_sprite.scale.x = 0.95
	difficulty_sprite.scale.y = 1.05
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	tween.tween_property(difficulty_sprite, 'modulate:a', 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(difficulty_sprite, 'position:y', 132.0, 0.25).set_trans(Tween.TRANS_EXPO)             
	tween.tween_property(difficulty_sprite, 'scale', Vector2.ONE, 0.25).set_trans(Tween.TRANS_BOUNCE)            


func calculate_high_score() -> void:
	var difficulty: String = difficulties[selected]
	var week: StoryWeekNode = weeks.get_child(StoryModeWeeks.selected_static)
	var suffix: String = week.difficulty_suffixes.mapping.get(difficulty, '')
	target_score = 0

	for raw_song: String in week.songs:
		var song: String = raw_song + suffix
		if not Scores.has_score(song, difficulty):
			high_score.text = 'High Score: N/A'
			break
		target_score += Scores.get_score(song, difficulty).get('score', 0)
