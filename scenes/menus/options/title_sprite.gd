@tool
extends AnimatedSprite


var timer: float = 0.0


func _process(delta: float) -> void:
	timer += delta
	rotation_degrees = sin(timer) * 4.0
	offset.y = cos(timer) * 4.0
