extends ColorRect


func _ready() -> void:
	color.a = Config.get_value("interface", "underlay_alpha") / 100.0
