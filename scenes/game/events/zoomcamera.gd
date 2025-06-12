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
	_apply_ease(tween, ease_string)
	tween.tween_property(game, ^'target_camera_zoom', Vector2(zoom, zoom),
			Conductor.beat_delta / 4.0 * float(steps))
	tween.tween_property(camera, ^'zoom', Vector2(zoom, zoom),
			Conductor.beat_delta / 4.0 * float(steps))


func convert_flixel_tween_ease(v: String) -> Tween.EaseType:
	if v.ends_with('Out'):
		return Tween.EASE_OUT
	if v.ends_with('InOut'):
		return Tween.EASE_IN_OUT
	if v.ends_with('OutIn'):
		return Tween.EASE_OUT_IN
	return Tween.EASE_IN


func convert_flixel_tween_trans(v: String) -> Tween.TransitionType:
	match v:
		'sineIn', 'sineOut', 'sineInOut', 'sineOutIn':
			return Tween.TRANS_SINE
		'cubeIn', 'cubeOut', 'cubeInOut', 'cubeOutIn':
			return Tween.TRANS_CUBIC
		'quadIn', 'quadOut', 'quadInOut', 'quadOutIn':
			return Tween.TRANS_QUAD
		'quartIn', 'quartOut', 'quartInOut', 'quartOutIn':
			return Tween.TRANS_QUART
		'quintIn', 'quintInOut', 'quintInOut', 'quintOutIn':
			return Tween.TRANS_QUINT
		'expoIn', 'expoOut', 'expoInOut', 'expoOutIn':
			return Tween.TRANS_EXPO
		'smoothStepIn', 'smoothStepOut', 'smoothStepInOut', 'smoothStepOutIn':
			return Tween.TRANS_SPRING # i think?
		'elasticIn', 'elasticOut', 'elasticInOut', 'elasticOutIn':
			return Tween.TRANS_ELASTIC
		_: # default to linear
			return Tween.TRANS_LINEAR


func _apply_ease(tween: Tween, ease_string: String) -> void:
	tween.set_ease(convert_flixel_tween_ease(ease_string))
	tween.set_trans(convert_flixel_tween_trans(ease_string))
