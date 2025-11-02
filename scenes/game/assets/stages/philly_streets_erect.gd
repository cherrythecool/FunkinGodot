extends Stage


@onready var car_path_1: Path2D = %car_path_1
@onready var car_follower_1: PathFollow2D = car_path_1.get_node(^"car_follow")
@onready var car_1: AnimatedSprite = car_follower_1.get_node(^"car")
var car_waiting: bool = false
var car_1_interruptable: bool = true

@onready var car_path_2: Path2D = %car_path_2
@onready var car_follower_2: PathFollow2D = car_path_2.get_node(^"car_follow")
@onready var car_2: AnimatedSprite = car_follower_2.get_node(^"car")
var car_2_interruptable: bool = true

@onready var traffic: AnimatedSprite = $cars/traffic
var light_state: bool = false
var last_change: int = 0
var change_interval: int = 8

@onready var mist_one: Sprite2D = $mist_one.get_node(^'sprite')
@onready var mist_two: Sprite2D = $mist_two.get_node(^'sprite')
@onready var mist_three: Sprite2D = $mist_three.get_node(^'sprite')
@onready var mist_four: Sprite2D = $mist_four.get_node(^'sprite')
@onready var mist_five: Sprite2D = $mist_five.get_node(^'sprite')
@onready var mist_six: Sprite2D = $mist_six.get_node(^'sprite')
var timer: float = 0.0


func _ready() -> void:
	game.player.offset_camera_position(Vector2(-250.0, -35.0))
	game.opponent.offset_camera_position(Vector2(230.0, 75.0))

	var color_material: ShaderMaterial = ShaderMaterial.new()
	color_material.shader = load('uid://bgwusoh6kicj3')
	color_material.set_shader_parameter('hue', -5.0)
	color_material.set_shader_parameter('saturation', -40.0)
	color_material.set_shader_parameter('contrast', -25.0)
	color_material.set_shader_parameter('brightness', -20.0)

	game.player.set_character_material(color_material)
	game.spectator.set_character_material(color_material)
	game.opponent.set_character_material(color_material)
	reset_cars(true, true)


func _on_beat_hit(beat: int) -> void:
	super(beat)

	var target_beat: int = last_change + change_interval
	if randf_range(0.0, 100.0) <= 10.0 and beat != target_beat and car_1_interruptable:
		if light_state:
			drive_car_1()
		else:
			drive_car_1_lights()

	if randf_range(0.0, 100.0) <= 10.0 and beat != target_beat and car_2_interruptable \
			and not light_state:
		drive_car_2_back()

	if beat == target_beat:
		change_lights()


func _process(delta: float) -> void:
	timer += delta
	mist_one.position.y = 660.0 + (sin(timer * 0.35) * 70.0) + 50.0
	mist_two.position.y = 500.0 + (sin(timer * 0.3) * 80.0) + 100.0
	mist_three.position.y = 540.0 + (sin(timer * 0.4) * 50.0) + 80.0
	mist_four.position.y = 230.0 + (sin(timer * 0.3) * 70.0) + 50.0
	mist_five.position.y = 170.0 + (sin(timer * 0.35) * 50.0) + 125.0
	mist_six.position.y = -80.0 + (sin(timer * 0.08) * 100.0)


func reset_cars(left: bool, right: bool) -> void:
	if left:
		car_waiting = false
		car_1_interruptable = true
		car_follower_1.progress_ratio = 1.0

	if right:
		car_2_interruptable = true
		car_follower_2.progress_ratio = 1.0


func change_lights() -> void:
	last_change = floori(Conductor.beat)
	light_state = not light_state
	if light_state:
		traffic.play(&'greentored')
		change_interval = 20
	else:
		traffic.play(&'redtogreen')
		change_interval = 30
		if car_waiting:
			finish_car_1_lights()


func drive_car_1() -> void:
	car_1_interruptable = false
	var variant: int = randi_range(1, 4)
	car_1.play(&'car%d' % [variant,])

	var offset: Vector2 = Vector2.ZERO
	var dur: float = 2.0
	match variant:
		1:
			dur = randf_range(1.0, 1.7)
		2:
			offset = Vector2(20.0, -15.0)
			dur = randf_range(0.6, 1.2)
		3:
			offset = Vector2(30.0, 50.0)
			dur = randf_range(1.5, 2.5)
		4:
			offset = Vector2(10.0, 60.0)
			dur = randf_range(1.5, 2.5)
	car_1.offset = -offset
	var tween: Tween = create_tween()
	car_follower_1.progress_ratio = 0.0
	tween.tween_property(car_follower_1, ^'progress_ratio', 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		car_1_interruptable = true)


func drive_car_1_lights() -> void:
	car_1_interruptable = false
	var variant: int = randi_range(1, 4)
	car_1.play(&'car%d' % [variant,])

	var offset: Vector2 = Vector2.ZERO
	var dur: float = 2.0
	match variant:
		1:
			dur = randf_range(1.0, 1.7)
		2:
			offset = Vector2(20.0, -15.0)
			dur = randf_range(0.9, 1.5)
		3:
			offset = Vector2(30.0, 50.0)
			dur = randf_range(1.5, 2.5)
		4:
			offset = Vector2(10.0, 60.0)
			dur = randf_range(1.5, 2.5)
	car_1.offset = -offset
	var tween: Tween = create_tween()
	car_follower_1.progress_ratio = 0.0
	tween.tween_property(car_follower_1, ^'progress_ratio', 0.175, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		car_waiting = true
		if not light_state:
			finish_car_1_lights())


func finish_car_1_lights() -> void:
	car_waiting = false
	car_follower_1.progress_ratio = 0.175
	var tween: Tween = create_tween()
	tween.tween_property(car_follower_1, ^'progress_ratio', 1.0, randf_range(1.8, 3.0)).set_delay(randf_range(0.2, 1.2))
	tween.tween_callback(func() -> void:
		car_1_interruptable = true)


func drive_car_2_back() -> void:
	car_2_interruptable = false
	
	var variant: int = randi_range(1, 4)
	car_2.play(&'car%d' % [variant,])
	car_2.flip_h = true

	var offset: Vector2 = Vector2.ZERO
	var dur: float = 2.0
	match variant:
		1:
			dur = randf_range(1.0, 1.7)
		2:
			offset = Vector2(20.0, -15.0)
			dur = randf_range(0.9, 1.5)
		3:
			offset = Vector2(30.0, 50.0)
			dur = randf_range(1.5, 2.5)
		4:
			offset = Vector2(10.0, 60.0)
			dur = randf_range(1.5, 2.5)
	car_2.offset = -offset
	car_follower_2.progress_ratio = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(car_follower_2, ^'progress_ratio', 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		car_2_interruptable = true
		car_follower_2.progress_ratio = 1.0
	)


func reset_stage() -> void:
	traffic.play(&'redtogreen')
