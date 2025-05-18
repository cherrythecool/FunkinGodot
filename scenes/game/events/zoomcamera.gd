extends FunkinScript


var tweens: Array[Tween] = []


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &'zoomcamera':
		return

	var data: Dictionary = event.data[0]
	var steps: int = data.get('duration', 32)
	var ease_string: String = data.get('ease', 'expoOut')
	var zoom: float = data.get('zoom', 1.05)
	if ease_string == 'INSTANT':
		for tween: Tween in tweens:
			tween.kill()
		tweens.clear()

		game.target_camera_zoom = Vector2(zoom, zoom)
		return

	var tween: Tween = create_tween()
	tweens.push_back(tween)
	tween.finished.connect(tweens.erase.bind(tween))

	_apply_ease(tween, ease_string)
	tween.tween_property(game, ^'target_camera_zoom', Vector2(zoom, zoom),
			Conductor.beat_delta / 4.0 * float(steps))


func _apply_ease(tween: Tween, ease_string: String) -> void:
	match ease_string:
		'expoOut':
			tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		'elasticInOut':
			tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
		'quadInOut':
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		'smoothStepInOut':
			tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		'circOut':
			tween.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		'quadOut':
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		'sineOut':
			tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		'sineInOut':
			tween.set_trans(Tween.TRANS_SINE)
		'linear': # default anyways
			pass
		_:
			printerr('Ease of %s not supported at this time.' % ease_string)
