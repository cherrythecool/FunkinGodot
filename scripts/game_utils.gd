extends Object
class_name GameUtils


# fix pesky 99.9999999999% accuracy or whatever with this simple trick
static func truncate_float_to(input: float, precision: int) -> float:
	var multiplier: float = pow(10.0, float(precision))
	return floori(input * multiplier) / multiplier


static func free_children_from(node: Node, immediate: bool = false) -> void:
	for child: Node in node.get_children():
		if immediate:
			child.free()
		else:
			child.queue_free()


static func free_from_array(nodes: Array[Node], immediate: bool = false) -> void:
	for child: Node in nodes:
		if not is_instance_valid(child):
			continue

		if immediate:
			child.free()
		else:
			child.queue_free()


# Shit from V-Slice mostly
static func convert_flixel_tween_ease(v: String) -> Tween.EaseType:
	if v.ends_with("Out"):
		return Tween.EASE_OUT
	if v.ends_with("InOut"):
		return Tween.EASE_IN_OUT
	if v.ends_with("OutIn"):
		return Tween.EASE_OUT_IN
	return Tween.EASE_IN


static func convert_flixel_tween_trans(v: String) -> Tween.TransitionType:
	match v:
		"sineIn", "sineOut", "sineInOut", "sineOutIn":
			return Tween.TRANS_SINE
		"cubeIn", "cubeOut", "cubeInOut", "cubeOutIn":
			return Tween.TRANS_CUBIC
		"quadIn", "quadOut", "quadInOut", "quadOutIn":
			return Tween.TRANS_QUAD
		"quartIn", "quartOut", "quartInOut", "quartOutIn":
			return Tween.TRANS_QUART
		"quintIn", "quintInOut", "quintInOut", "quintOutIn":
			return Tween.TRANS_QUINT
		"expoIn", "expoOut", "expoInOut", "expoOutIn":
			return Tween.TRANS_EXPO
		"smoothStepIn", "smoothStepOut", "smoothStepInOut", "smoothStepOutIn":
			## TODO: Maybe implement a custom smooth step function?
			return Tween.TRANS_CUBIC
		"elasticIn", "elasticOut", "elasticInOut", "elasticOutIn":
			return Tween.TRANS_ELASTIC
		_: # default to linear
			return Tween.TRANS_LINEAR


static func get_accurate_time(player: AudioStreamPlayer) -> float:
	return player.get_playback_position() + (AudioServer.get_time_since_last_mix() * player.pitch_scale)


static func lerp_weight(delta: float, constant: float) -> float:
	return minf(1.0 - exp(-constant * delta), 1.0)
