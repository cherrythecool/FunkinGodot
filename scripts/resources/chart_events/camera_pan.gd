class_name CameraPan extends EventData


enum Side {
	PLAYER = 0,
	OPPONENT = 1,
	GIRLFRIEND = 2,
}


func _init(new_time: float = 0.0, side: CameraPan.Side = Side.PLAYER) -> void:
	name = &'Camera Pan'
	data.push_back(side)
	time = new_time
