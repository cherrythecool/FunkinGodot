extends Marker2D


@export var do_countdown: bool = true
@export var pause_countdown: bool = false
@export var force_countdown: bool = false
@export var hud: Node

var countdown_offset: int = 0
var hud_skin: HUDSkin


func setup() -> void:
	Game.instance.ready_post.connect(_ready_post)
	Game.instance.unpaused.connect(countdown_resume)
	Conductor.beat_hit.connect(_on_beat_hit)
	
	var found: Resource = null
	if is_instance_valid(hud):
		if 'hud_skin' in hud:
			found = hud.hud_skin
	
	hud_skin = found if is_instance_valid(found) else load('uid://oxo327xfxemo')
	scale = hud_skin.countdown_scale


func countdown_resume() -> void:
	if not Config.get_value('interface', 'countdown_on_resume'):
		return
	if not Game.instance.song_started:
		return
	if Conductor.beat < 4.0:
		return
	if force_countdown:
		return

	Conductor.target_audio.seek(
		maxf(Conductor.raw_time - (4.0 * Conductor.beat_delta), 0.0)
	)
	countdown_offset = -floori(Conductor.beat) - 1
	force_countdown = true
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
	if (not do_countdown) and not force_countdown:
		return
	if (beat >= 0 or Game.instance.song_started) and not force_countdown:
		return

	if pause_countdown:
		Conductor.raw_time = -5.0 * Conductor.beat_delta
		return

	# countdown lol
	beat += countdown_offset
	if beat >= 0 and force_countdown:
		force_countdown = false
		return
	var index: int = clampi(4 - absi(beat), 0, 3)
	_display_countdown_sprite(index)
	_play_countdown_sound(index)


func _display_countdown_sprite(index: int) -> void:
	if not is_instance_valid(hud_skin):
		return
	
	# Don't display things that don't exist.
	if not is_instance_valid(hud_skin.countdown_textures[index]):
		return

	var sprite: Sprite2D = Sprite2D.new()
	sprite.scale = Vector2(1.05, 1.05)
	sprite.texture = hud_skin.countdown_textures[index]
	sprite.texture_filter = hud_skin.rating_filter
	add_child(sprite)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(sprite, ^'modulate:a', 0.0, Conductor.beat_delta)
	tween.tween_property(sprite, ^'scale', Vector2.ONE, Conductor.beat_delta)
	tween.tween_callback(sprite.queue_free).set_delay(Conductor.beat_delta)


func _play_countdown_sound(index: int) -> void:
	if not is_instance_valid(hud_skin):
		return
	
	# Don't play things that don't exist.
	if not is_instance_valid(hud_skin.countdown_sounds[index]):
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = hud_skin.countdown_sounds[index]
	player.bus = &'SFX'
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
