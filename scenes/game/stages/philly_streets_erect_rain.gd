extends CanvasLayer


func _ready() -> void:
	if (
		not Config.get_value("accessibility", "flashing_lights")
	) or (
		not Config.get_value("performance", "intensive_visuals")
	):
		queue_free()
