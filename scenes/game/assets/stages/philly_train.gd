extends Stage


@onready var window: Sprite2D = %window
var window_fade_value: float = 0.0

@onready var train: Sprite2D = %train
var train_timer: float = 0.0
var train_started: bool = false
var train_moving: bool = false
var train_finishing: bool = false
var train_cooldown: int = 0
var train_cars: int = 8

@onready var train_passes: AudioStreamPlayer = %train_passes

@export var light_colors: PackedColorArray = [
	Color('#31a2fd'),
	Color('#31fd8c'),
	Color('#fb33f5'),
	Color('#fd4531'),
	Color('#fba633'),
]


func _ready() -> void:
	_on_measure_hit(0)


func _process(delta: float) -> void:
	window_fade_value += Conductor.beat_delta * delta * 1.5
	window.material.set_shader_parameter(&'fade', window_fade_value)

	if not train_started:
		return

	train_timer += delta
	while train_timer >= 1.0 / 24.0:
		train_timer -= 1.0 / 24.0
		update_train_position()


func _on_beat_hit(beat: int) -> void:
	if not train_started:
		train_cooldown += 1
	else:
		return

	if beat % 8 != 4:
		return
	if randf_range(0.0, 100.0) > 30.0:
		return
	if train_cooldown < 8:
		return

	train_cooldown = randi_range(-4, 0)
	train_started = true
	train_passes.play()


func _on_measure_hit(measure: int) -> void:
	if measure < 0:
		return

	window_fade_value = 0.0
	window.modulate = light_colors[randi_range(0, light_colors.size() - 1)]


func reset_train() -> void:
	game.spectator.play_anim(&'hair_fall', true, true)
	game.spectator.animation_finished.connect(func(_animation: StringName) -> void:
		game.spectator.dance(), CONNECT_ONE_SHOT)
	train.position.x = 1280.0 + 200.0
	train_started = false
	train_moving = false
	train_finishing = false
	train_cars = 8


func update_train_position() -> void:
	if Global.get_accurate_time(train_passes) >= 4.7 and not train_moving:
		train_moving = true
		game.spectator.play_anim(&'hair_blow', false, true)

	if train_moving:
		train.position.x -= 400.0

		if train.position.x < -2000.0 and not train_finishing:
			train.position.x = -1150.0
			train_cars -= 1

			if train_cars == 0:
				train_finishing = true

		if train.position.x < -4000.0 and train_finishing:
			reset_train()
