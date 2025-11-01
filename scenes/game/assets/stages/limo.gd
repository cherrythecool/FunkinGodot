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


func _ready() -> void:
	game.player.offset_camera_position(Vector2(-225.0, -25.0))
	reset_fast_car()


func _process(delta: float) -> void:
	fast_car.position.x += delta * fast_car_vel


func _on_beat_hit(beat: int) -> void:
	super(beat)
	dance_left = beat % 2 == 0
	for dancer: AnimatedSprite2D in dancers.get_children():
		dancer.play('left' if dance_left else 'right')

	if randi_range(1, 100) <= 10 and fast_car_can:
		drive_fast_car()


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
