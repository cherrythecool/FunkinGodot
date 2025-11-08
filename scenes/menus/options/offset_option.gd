extends NumberOption


func _value_changed() -> void:
	super()
	Conductor.reset_offset()
