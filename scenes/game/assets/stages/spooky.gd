extends Stage


@export var sounds: Array[AudioStream] = []

@onready var background: AnimatedSprite = %background
var previous_clear_color: Color

var lightning_beat: int = 0
var lightning_offset: int = 8


func _enter_tree() -> void:
	previous_clear_color = RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color('#242336'))


func _exit_tree() -> void:
	RenderingServer.set_default_clear_color(previous_clear_color)


func _ready() -> void:
	game.spectator.camera_offset.position.y += 75.0


func _on_beat_hit(beat: int) -> void:
	super(beat)

	if beat == 4 and game.song.to_lower() == &'spookeez':
		strike(beat, false)
	if randf_range(0.0, 100.0) >= 90.0 and beat > lightning_beat + lightning_offset:
		strike(beat, true)


func strike(beat: int, play_sound: bool = true) -> void:
	lightning_beat = beat
	lightning_offset = randi_range(8, 24)

	if play_sound:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.stream = sounds.pick_random()
		add_child(player)

		player.play()
		player.finished.connect(player.queue_free)

	background.play(&'halloweem bg lightning strike')

	if game.spectator.has_anim(&'scared'):
		game.spectator.play_anim(&'scared', true, true)
	if game.player.has_anim(&'scared'):
		game.player.play_anim(&'scared', true, true)
