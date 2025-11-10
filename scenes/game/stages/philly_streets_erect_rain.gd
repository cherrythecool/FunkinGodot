extends CanvasLayer


func _ready() -> void:
	if not Config.get_value('accessibility', 'flashing_lights'):
		queue_free()
