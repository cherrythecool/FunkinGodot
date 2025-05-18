extends Stage


@onready var car_1: AnimatedSprite = $'cars/1'
var car_waiting: bool = false
var car_1_interruptable: bool = true
var car_1_tweens: Array[Tween] = []

@onready var car_2: AnimatedSprite = $'cars/2'
var car_2_interruptable: bool = true
var car_2_tweens: Array[Tween] = []

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
	game.player.z_index += 400
	game.player._camera_offset.position += Vector2(-250.0, -35.0)
	game.spectator.z_index += 300
	game.opponent.z_index += 350
	game.opponent._camera_offset.position += Vector2(230.0, 75.0)
	var plr: AnimatedSprite = game.player.get_node(^'sprite')
	plr.material = ShaderMaterial.new()
	plr.material.shader = load('uid://bgwusoh6kicj3')
	plr.material.set_shader_parameter('hue', -5.0)
	plr.material.set_shader_parameter('saturation', -40.0)
	plr.material.set_shader_parameter('contrast', -25.0)
	plr.material.set_shader_parameter('brightness', -20.0)

	game.spectator.get_node(^'sprite').material = plr.material
	if game.spectator.has_node(^'speakers'):
		game.spectator.get_node(^'speakers').material = plr.material

	game.opponent.get_node(^'sprite').material = plr.material
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


func cancel_tween(tween: Tween) -> void:
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()


func reset_cars(left: bool, right: bool) -> void:
	if left:
		car_waiting = false
		car_1_interruptable = true
		for tween: Tween in car_1_tweens:
			cancel_tween(tween)
		car_1.position.x = 1200.0
		car_1.position.y = 818.0
		car_1.rotation_degrees = 0.0

	if right:
		car_2_interruptable = true
		for tween: Tween in car_2_tweens:
			cancel_tween(tween)
		car_2.position.x = 1200.0
		car_2.position.y = 818.0
		car_2.rotation_degrees = 0.0


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
	for tween: Tween in car_1_tweens:
		cancel_tween(tween)
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
	var path_offset: Vector2 = Vector2(306.6, 168.3)
	stupid_car_1_movement(dur, 0.0, -8.0, 18.0,
			[Vector2(1570.0 - path_offset.x, 1049.0 - path_offset.y - 30.0),
			Vector2(1770.0 - path_offset.x, 980.0 - path_offset.y - 50.0),
			Vector2(1950.0 - path_offset.x, 1127.0 - path_offset.y + 40.0),])\
					.tween_callback(func() -> void:
						car_1_interruptable = true)


func drive_car_1_lights() -> void:
	car_1_interruptable = false
	for tween: Tween in car_1_tweens:
		cancel_tween(tween)
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
	var path_offset: Vector2 = Vector2(306.6, 168.3)
	stupid_car_1_movement(dur, 0.0, -7.0, -5.0,
			[Vector2(1500.0 - path_offset.x - 20.0, 1049.0 - path_offset.y - 20.0),
			Vector2(1770.0 - path_offset.x - 80.0, 994.0 - path_offset.y + 10.0),
			Vector2(1950.0 - path_offset.x - 80.0, 980.0 - path_offset.y + 15.0),])\
			.tween_callback(func() -> void:
				car_waiting = true
				if not light_state:
					finish_car_1_lights())


func finish_car_1_lights() -> void:
	car_waiting = false
	var offset: Vector2 = Vector2(306.6, 168.3)
	stupid_car_1_movement(randf_range(1.8, 3.0), randf_range(0.2, 1.2), -5.0, 18.0,
			[Vector2(1950.0 - offset.x - 80.0, 980.0 - offset.y + 15.0),
			Vector2(2400.0 - offset.x, 980.0 - offset.y - 50.0),
			Vector2(3102.0 - offset.x, 1127.0 - offset.y + 40.0),])\
				.tween_callback(func() -> void:
					car_1_interruptable = true)


func stupid_car_1_movement(dur: float, delay: float, rt_s: float, rt_f: float,
		path: Array[Vector2]) -> Tween:
	car_1.rotation_degrees = rt_s
	var angle_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	angle_tween.tween_property(car_1, ^'rotation_degrees', rt_f, dur).set_delay(delay)
	car_1_tweens.push_back(angle_tween)

	car_1.global_position = path[0]
	var movement_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	movement_tween.tween_property(car_1, ^'global_position', path[1], dur / 2.0).set_delay(delay)
	movement_tween.tween_property(car_1, ^'global_position', path[2], dur / 2.0)
	car_1_tweens.push_back(movement_tween)
	return movement_tween


func stupid_car_2_movement(dur: float, delay: float, rt_s: float, rt_f: float,
		path: Array[Vector2]) -> Tween:
	car_2.rotation_degrees = rt_s
	var angle_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	angle_tween.tween_property(car_2, ^'rotation_degrees', rt_f, dur).set_delay(delay)
	car_2_tweens.push_back(angle_tween)

	car_2.global_position = path[0]
	var movement_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	movement_tween.tween_property(car_2, ^'global_position', path[1], dur / 2.0).set_delay(delay)
	movement_tween.tween_property(car_2, ^'global_position', path[2], dur / 2.0)
	car_2_tweens.push_back(movement_tween)

	return movement_tween


func drive_car_2_back() -> void:
	car_2_interruptable = false
	for tween: Tween  in car_2_tweens:
		cancel_tween(tween)
	var variant: int = randi_range(1, 4)
	car_2.play(&'car%d' % [variant,])

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
	var path_offset: Vector2 = Vector2(306.6, 168.3)
	stupid_car_2_movement(dur, 0.0, 18.0, -8.0,
			[Vector2(3102.0 - path_offset.x, 1127.0 - path_offset.y + 60.0),
			Vector2(1770.0 - path_offset.x, 980.0 - path_offset.y - 30.0),
			Vector2(1950.0 - path_offset.x, 1049.0 - path_offset.y - 10.0),])\
				.tween_callback(func() -> void:
					car_2_interruptable = true)


func reset_stage() -> void:
	traffic.play(&'redtogreen')
