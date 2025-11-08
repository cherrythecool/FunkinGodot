class_name Stage extends Node2D


@onready var game: Game = Game.instance
@export_range(0.01, 4.0, 0.01) var default_zoom: float = 1.05
@export_range(0.0, 10.0, 0.01) var camera_speed: float = 1.0


func _init() -> void:
	if is_instance_valid(Conductor.instance):
		Conductor.instance.beat_hit.connect(_on_beat_hit)
		Conductor.instance.step_hit.connect(_on_step_hit)
		Conductor.instance.measure_hit.connect(_on_measure_hit)


func _on_beat_hit(_beat: int) -> void:
	pass


func _on_step_hit(_step: int) -> void:
	pass


func _on_measure_hit(_measure: int) -> void:
	pass
