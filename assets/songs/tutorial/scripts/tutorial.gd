extends FunkinScript


func _ready() -> void:
	super()
	
	if not (is_instance_valid(spectator) and is_instance_valid(player)):
		queue_free()
		return
	
	spectator._camera_offset.position += Vector2(50.0, 50.0)
	
	create_tween().set_trans(Tween.TRANS_ELASTIC).tween_property(
		camera, 'zoom', Vector2(1.3, 1.3), Conductor.beat_delta)
	
	if opponent.name == &'null':
		game.opponent = spectator
		game.spectator = null
		opponent = spectator
		spectator = game.spectator
		
		game.target_camera_position = opponent._camera_offset.global_position
		camera.position = game.target_camera_position
		
		game.hud.health_bar.reload_icons()
		opponent_field._default_character = opponent


func _process(delta: float) -> void:
	game.camera_bumps = false


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &'camera pan':
		return
	if event.data[0] == CameraPan.Side.PLAYER:
		create_tween().set_trans(Tween.TRANS_ELASTIC).tween_property(
			camera, 'zoom', Vector2.ONE, Conductor.beat_delta)
	else:
		create_tween().set_trans(Tween.TRANS_ELASTIC).tween_property(
			camera, 'zoom', Vector2(1.3, 1.3), Conductor.beat_delta)
