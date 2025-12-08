extends Marker2D
class_name CountdownContainer


@export var do_countdown: bool = true
@export var pause_countdown: bool = false
@export var force_countdown: bool = false
@export var hud: Node

var countdown_offset: int = 0
var hud_skin: HUDSkin:
	set(v):
		hud_skin = v
		countdown_textures = hud_skin.get_countdown_textures()
		countdown_sounds = hud_skin.get_countdown_sounds()

var countdown_textures: Array[Texture2D] = []
var countdown_sounds: Array[AudioStream] = []

var game: Game


func _on_hud_setup() -> void:
	game = Game.instance
	if game.metadata.skip_countdown:
		do_countdown = false
	
	game.ready_post.connect(_ready_post)
	game.unpaused.connect(countdown_resume)
	game.conductor.beat_hit.connect(_on_beat_hit)
	
	var found: Resource = null
	if is_instance_valid(hud) and 'hud_skin' in hud:
		found = hud.hud_skin
	
	hud_skin = (
		found if is_instance_valid(found) else
		load('uid://oxo327xfxemo')
	)
	scale = hud_skin.countdown_scale


func countdown_resume() -> void:
	if not Config.get_value('interface', 'countdown_on_resume'):
		return
	if not is_instance_valid(game):
		return
	if not game.song_started:
		return
	if game.conductor.beat < 4.0:
		return
	if force_countdown:
		return

	game.conductor.target_audio.seek(
		maxf(game.conductor.raw_time - (4.0 * game.conductor.beat_delta), 0.0)
	)
	countdown_offset = -floori(game.conductor.beat) - 1
	force_countdown = true
	pause_countdown = false

	game.conductor.target_audio.volume_linear = 0.0
	create_tween().tween_property(
		game.conductor.target_audio,
		^'volume_linear',
		1.0,
		3.5 * game.conductor.beat_delta
	)


func _ready_post() -> void:
	if not do_countdown:
		game.conductor.raw_time = 0.0


func _on_beat_hit(beat: int) -> void:
	if not is_instance_valid(Game.instance):
		return
	if (not do_countdown) and not force_countdown:
		return
	if (beat >= 0 or Game.instance.song_started) and not force_countdown:
		return

	if pause_countdown:
		game.conductor.raw_time = -5.0 * game.conductor.beat_delta
		return

	# countdown lol
	beat += countdown_offset
	if beat >= 0 and force_countdown:
		force_countdown = false
		return
	var index: int = clampi(4 - absi(beat), 0, 3)
	display_countdown_sprite(index)
	play_countdown_sound(index)


func display_countdown_sprite(index: int) -> void:
	if not is_instance_valid(hud_skin):
		return
	if index > countdown_textures.size() - 1:
		return
	if not is_instance_valid(countdown_textures[index]):
		return

	var sprite: Sprite2D = Sprite2D.new()
	sprite.scale = Vector2(1.05, 1.05)
	sprite.texture = countdown_textures[index]
	sprite.texture_filter = hud_skin.rating_filter
	add_child(sprite)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(sprite, ^'modulate:a', 0.0, game.conductor.beat_delta)
	tween.tween_property(sprite, ^'scale', Vector2.ONE, game.conductor.beat_delta)
	tween.tween_callback(sprite.queue_free).set_delay(game.conductor.beat_delta)


func play_countdown_sound(index: int) -> void:
	if index > countdown_sounds.size() - 1:
		return
	if not is_instance_valid(countdown_sounds[index]):
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = countdown_sounds[index]
	player.bus = &'SFX'
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
