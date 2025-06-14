class_name Timeline extends Resource


@export var layers: Array[Layer] = []
@export var length: int = 0


func _calculate_duration() -> void:
	var longest := 0
	for layer in layers:
		if layer.length > longest:
			longest = layer.length

	length = longest


func parse_unoptimized(input: Dictionary) -> void:
	var raw_layers: Array = input.get('LAYERS', [])
	for raw_layer: Dictionary in raw_layers:
		var layer := Layer.new()
		layer.name = StringName(raw_layer.get('Layer_name', ''))
		layer.parse_unoptimized(raw_layer)
		layers.push_back(layer)

	_calculate_duration()


func parse_optimized(input: Dictionary) -> void:
	var raw_layers: Array = input.get('L', [])
	for raw_layer: Dictionary in raw_layers:
		var layer := Layer.new()
		layer.name = StringName(raw_layer.get('LN', ''))
		layer.parse_optimized(raw_layer)
		layers.push_back(layer)

	_calculate_duration()
