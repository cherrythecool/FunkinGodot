extends FunkinScript


var tween: Tween = null


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &'zoomcamera':
		return

	var data: Dictionary = event.data[0]
	var steps: int = data.get('duration', 32)
	var ease_string: String = data.get('ease', 'expoOut')
	var zoom: float = data.get('zoom', 1.05)

	if is_instance_valid(tween):
		tween.kill()

	if ease_string == 'INSTANT':
		game.target_camera_zoom = Vector2(zoom, zoom)
		camera.zoom = Vector2(zoom, zoom)
		return

	tween = create_tween().set_parallel()
	tween.set_ease(Global.convert_flixel_tween_ease(ease_string))
	tween.set_trans(Global.convert_flixel_tween_trans(ease_string))
	tween.tween_property(game, ^'target_camera_zoom', Vector2(zoom, zoom),
			Conductor.beat_delta / 4.0 * float(steps))
	tween.tween_property(camera, ^'zoom', Vector2(zoom, zoom),
			Conductor.beat_delta / 4.0 * float(steps))
