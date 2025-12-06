class_name GameCamera2D extends Camera2D


static var camera_position: Vector2 = Vector2.INF
static var camera_zoom: Vector2 = Vector2.INF
static var instance: GameCamera2D = null

@export var conductor: Conductor = null
@export var persistent_position: bool = true
@export var persistent_zoom: bool = true

@export_group("Position Lerping")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var position_lerps: bool = true
@export var position_target: Vector2 = Vector2.ZERO
@export_range(0.0, 2.0, 0.1, "or_greater") var position_lerp_speed: float = 1.0

@export_group("Zoom Lerping")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var zoom_lerps: bool = true
@export_custom(PROPERTY_HINT_LINK, "") var zoom_target: Vector2 = Vector2(1.05, 1.05)
@export_range(0.0, 2.0, 0.1, "or_greater") var zoom_lerp_speed: float = 1.0

@export_group("Camera Bumping")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var bumps: bool = true
@export_custom(PROPERTY_HINT_LINK, "") var bump_amount: Vector2 = Vector2(0.015, 0.015)
@export_range(1, 16, 1, "or_greater") var bump_interval: int = 4

var game: Game:
	get:
		return Game.instance
var zoom_tween: Tween
var pan_tween: Tween
var pan_lerped: bool


func _ready() -> void:
	if not is_instance_valid(instance):
		instance = self
	if camera_position != Vector2.INF and persistent_position:
		position = camera_position
	if camera_zoom != Vector2.INF and persistent_zoom:
		zoom = camera_zoom


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _process(delta: float) -> void:
	if persistent_position:
		camera_position = position
	if persistent_zoom:
		camera_zoom = zoom
	
	if position_lerps:
		position = position.lerp(position_target, delta * 3.0 * position_lerp_speed)
	if zoom_lerps:
		zoom = zoom.lerp(zoom_target, delta * 3.0 * zoom_lerp_speed)


func _on_beat_hit(beat: int) -> void:
	if not bumps:
		return
	if beat <= 0:
		return
	if beat % bump_interval == 0:
		zoom += bump_amount


func _on_first_opponent_note(_note: Note) -> void:
	bumps = true


func _on_game_event_hit(event: EventData) -> void:
	match event.name.to_lower():
		&"camera pan":
			var target: Character = null
			var side: CameraPan.Side = event.data[0]
			match side:
				CameraPan.Side.PLAYER:
					target = game.player
				CameraPan.Side.OPPONENT:
					target = game.opponent
				CameraPan.Side.GIRLFRIEND:
					target = game.spectator
			if not is_instance_valid(target):
				return
			
			if is_instance_valid(pan_tween) and pan_tween.is_running():
				pan_tween.kill()
			
			var ease_string: String = event.data[1]
			position_lerps = true
			position_target = target.get_camera_position() + event.data[3]
			if event.time <= 0.0 or ease_string == "INSTANT":
				position = position_target
			if ease_string == "CLASSIC" or ease_string == "INSTANT":
				return
			
			var steps: float = event.data[2]
			pan_tween = create_tween()
			pan_tween.set_ease(Global.convert_flixel_tween_ease(ease_string))
			pan_tween.set_trans(Global.convert_flixel_tween_trans(ease_string))
			pan_tween.tween_property(
				self,
				^"position_lerps",
				false,
				0.0
			)
			
			pan_tween.tween_property(
				self,
				^"position",
				position_target,
				conductor.beat_delta / 4.0 * float(steps)
			)
			
			pan_tween.tween_property(
				self,
				^"position_lerps",
				true,
				0.0
			)
		&"zoomcamera":
			var data: Dictionary = event.data[0]
			var steps: int = data.get("duration", 32)
			var ease_string: String = data.get("ease", "expoOut")
			var data_zoom: float = data.get("zoom", 1.05)
			if is_instance_valid(zoom_tween):
				zoom_tween.kill()

			match data.get("mode", "direct"):
				"stage":
					data_zoom *= game.stage.default_zoom
				"direct":
					pass

			if ease_string == "INSTANT" or event.time <= 0.0:
				zoom_target = Vector2.ONE * data_zoom
				zoom = Vector2.ONE * data_zoom
				return
			if not is_instance_valid(conductor):
				conductor = Conductor.instance
			if not is_instance_valid(conductor):
				return
			
			zoom_tween = create_tween().set_parallel()
			zoom_tween.set_ease(Global.convert_flixel_tween_ease(ease_string))
			zoom_tween.set_trans(Global.convert_flixel_tween_trans(ease_string))
			zoom_tween.tween_property(
				self,
				^"zoom_target",
				Vector2.ONE * data_zoom,
				conductor.beat_delta / 4.0 * float(steps)
			)
			zoom_tween.tween_property(
				self,
				^"zoom",
				Vector2.ONE * data_zoom,
				conductor.beat_delta / 4.0 * float(steps)
			)


func _on_game_ready_post() -> void:
	if not is_instance_valid(conductor):
		conductor = Conductor.instance
	
	if is_instance_valid(game.stage):
		zoom_target = Vector2.ONE * game.stage.default_zoom
		zoom = zoom_target
		position_lerp_speed = game.stage.camera_speed
	if is_instance_valid(game.opponent_field):
		game.opponent_field.note_hit.connect(
			_on_first_opponent_note,
			CONNECT_ONE_SHOT
		)
	
	if camera_position != Vector2.INF and persistent_position:
		position = camera_position
	if camera_zoom != Vector2.INF and persistent_zoom:
		zoom = camera_zoom
	
	reset_persistent_values()


func _on_game_song_exited() -> void:
	persistent_position = false
	persistent_zoom = false
	reset_persistent_values()


static func reset_persistent_values() -> void:
	camera_position = Vector2.INF
	camera_zoom = Vector2.INF
