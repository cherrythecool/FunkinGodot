extends Stage


@export var car_sounds: Array[AudioStream] = []

@onready var fast_car: Sprite2D = %fast_car
@onready var car_timer: Timer = %car_timer
@onready var car_pass: AudioStreamPlayer = %car_pass

@onready var player_offset: Marker2D = %player
@onready var spectator_offset: Marker2D = %spectator
@onready var opponent_offsett: Marker2D = %opponent

@onready var dancers: Parallax2D = %dancers
var dance_left: bool = false

var fast_car_can: bool = false
var fast_car_vel: float = 0.0

@onready var star_sprite: AnimatedSprite = $stars/sprite
var star_beat: int = 0
var star_offset: int = 2

@onready var mists: Array[Node2D] = [
	$mist_1/sprite,
	$mist_2/sprite,
	$mist_3/sprite,
	$mist_4/sprite,
	$mist_5/sprite,
]

var mist_timer: float = 0.0


func _ready() -> void:
	game.player.camera_offset.position.x -= 225.0
	game.player.camera_offset.position.y -= 25.0

	game.player.set_character_material(fast_car.material)
	game.opponent.set_character_material(fast_car.material)
	game.spectator.set_character_material(fast_car.material)

	reset_fast_car()


func _process(delta: float) -> void:
	fast_car.position.x += delta * fast_car_vel

	mist_timer += delta

	mists[0].position.y = 100.0 + (sin(mist_timer) * 200.0)
	mists[1].position.y = sin(mist_timer * 0.8) * 100.0
	mists[2].position.y = -20.0 + (sin(mist_timer * 0.5) * 200.0)
	mists[3].position.y = -180.0 + (sin(mist_timer * 0.4) * 300.0)
	mists[4].position.y = -450.0 + (sin(mist_timer * 0.2) * 150.0)


func _on_beat_hit(beat: int) -> void:
	super(beat)
	dance_left = beat % 2 == 0
	for dancer: AnimatedSprite2D in dancers.get_children():
		dancer.play('left' if dance_left else 'right')

	if randi_range(1, 100) <= 10 and fast_car_can:
		drive_fast_car()

	if randi_range(1, 100) <= 10 and beat > star_beat + star_offset:
		do_star(beat)


func do_star(beat: int) -> void:
	star_sprite.position.x = randf_range(50.0, 900.0)
	star_sprite.position.y = randf_range(-10.0, 20.0)
	star_sprite.flip_h = randi_range(0, 100) < 50
	star_sprite.play(&'shooting star')

	star_beat = beat
	star_offset = randi_range(4, 8)


func reset_fast_car() -> void:
	fast_car_vel = 0.0
	fast_car.position.x = -24_000.0
	fast_car.position.y = randf_range(140.0, 250.0)
	fast_car_can = true


func drive_fast_car() -> void:
	if not car_sounds.is_empty():
		car_pass.stream = car_sounds.pick_random()
		car_pass.play()

	fast_car_vel = randf_range(170.0, 220.0) * 3.0 * 33.0
	fast_car_can = false
	car_timer.start()
