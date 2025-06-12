class_name BPMChange extends EventData


func _init(new_time: float = 0.0, bpm: float = -1.0) -> void:
	name = &'BPM Change'
	if bpm >= 0.0:
		data.push_back(bpm)
	else:
		data.push_back(0.001)
	time = new_time
