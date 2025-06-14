class_name AtlasAnimation extends Resource


enum AtlasFormat {
	UNOPTIMIZED = 0,
	OPTIMIZED
}

@export var name: StringName
@export var symbol_name: StringName
@export var symbol_dictionary: Dictionary[StringName, Timeline] = {}
@export var timeline: Timeline
@export var format: AtlasFormat = AtlasFormat.UNOPTIMIZED
@export var framerate: float = 30.0


static func load_from_json(input: Dictionary) -> AtlasAnimation:
	var animation := AtlasAnimation.new()
	if input.has('ANIMATION'):
		animation.format = AtlasFormat.UNOPTIMIZED
		animation.parse_unoptimized(input)
	else:
		animation.format = AtlasFormat.OPTIMIZED
		animation.parse_optimized(input)

	return animation


func parse_unoptimized(input: Dictionary) -> void:
	var animation: Dictionary = input.get('ANIMATION', {})
	name = StringName(animation.get('name', ''))
	symbol_name = StringName(animation.get('SYMBOL_name', ''))
	timeline = Timeline.new()
	timeline.parse_unoptimized(animation.get('TIMELINE', {}))

	var metadata: Dictionary = input.get('metadata', {})
	framerate = metadata.get('framerate', 30.0)

	var symbol_dictionary_raw: Dictionary = input.get('SYMBOL_DICTIONARY', {})
	var symbols: Array = symbol_dictionary_raw.get('Symbols', [])
	for symbol: Dictionary in symbols:
		var symbol_timeline := Timeline.new()
		symbol_timeline.parse_unoptimized(symbol.get('TIMELINE', {}))
		symbol_dictionary.set(StringName(symbol.get('SYMBOL_name', '')), symbol_timeline)


func parse_optimized(input: Dictionary) -> void:
	var animation: Dictionary = input.get('AN', {})
	name = StringName(animation.get('N', ''))
	symbol_name = StringName(animation.get('SN', ''))
	timeline = Timeline.new()
	timeline.parse_optimized(animation.get('TL', {}))

	var metadata: Dictionary = input.get('MD', {})
	framerate = metadata.get('FRT', 30.0)

	var symbol_dictionary_raw: Dictionary = input.get('SD', {})
	var symbols: Array = symbol_dictionary_raw.get('S', [])
	for symbol: Dictionary in symbols:
		var symbol_timeline := Timeline.new()
		symbol_timeline.parse_optimized(symbol.get('TL', {}))
		symbol_dictionary.set(StringName(symbol.get('SN', '')), symbol_timeline)
