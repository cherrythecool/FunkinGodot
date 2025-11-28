class_name CameraPan extends EventData


enum Side {
	PLAYER = 0,
	OPPONENT = 1,
	GIRLFRIEND = 2,
}


func _init(new_time: float = 0.0,
		side: CameraPan.Side = Side.PLAYER,
		ease_string: String = 'CLASSIC',
		duration: float = 32.0,
		offset: Vector2 = Vector2.ZERO) -> void:
	name = &'Camera Pan'
	data.push_back(side)
	data.push_back(ease_string)
	data.push_back(duration)
	data.push_back(offset)
	time = new_time
