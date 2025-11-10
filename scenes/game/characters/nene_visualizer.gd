extends Node2D


@export var updates_per_second: float = 24.0

var timer: float = 0.0
var max_hz: float = 11025.0
var min_db: float = 60.0
var spectrum: AudioEffectSpectrumAnalyzerInstance
var targets: Array


func _ready() -> void:
	AudioServer.set_bus_effect_enabled(1, 0, true)
	targets = get_children()
	spectrum = AudioServer.get_bus_effect_instance(1, 0)
	_update()


func _update() -> void:
	var prev_hz: float = 0.0
	for i: int in targets.size():
		var hz: float = float(i) * max_hz / float(targets.size())
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy: float = clampf((min_db + linear_to_db(magnitude)) / min_db, 0.0, 1.0)
		var silly: float = remap(energy, 0.0, 1.0, 0.0, 5.0)
		targets[i].frame = int(5.0 - silly)
		prev_hz = hz


func _process(delta: float) -> void:
	timer += delta
	if timer >= 1.0 / updates_per_second:
		_update()
		timer = 0.0


func _exit_tree() -> void:
	AudioServer.set_bus_effect_enabled(1, 0, false)
