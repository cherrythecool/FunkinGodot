extends FunkinScript


func _on_event_hit(event: EventData) -> void:
	super(event)

	if event.name.to_lower() == &'camera pan':
		var target: Character = spectator
		match event.data[0]:
			CameraPan.Side.PLAYER:
				target = player
			CameraPan.Side.OPPONENT:
				target = opponent
		if not is_instance_valid(target):
			return
		
		game.target_camera_position = target.get_camera_position()
		if event.time <= 0.0:
			camera.position = game.target_camera_position
