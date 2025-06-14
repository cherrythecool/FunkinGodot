class_name SymbolElement extends Element


enum SymbolType {
	GRAPHIC = 0,
	MOVIE_CLIP
}

enum SymbolLoopMode {
	LOOP = 0,
	ONE_SHOT,
	FREEZE_FRAME,
	REVERSE_ONE_SHOT,
	REVERSE_LOOP
}

@export var instance_name: StringName
@export var symbol_type: SymbolType
@export var frame: int
@export var loop_mode: SymbolLoopMode


func _init() -> void:
	type = ElementType.SYMBOL


func parse_unoptimized(input: Dictionary) -> void:
	var symbol: Dictionary = input.get('SYMBOL_Instance', {})
	name = StringName(symbol.get('SYMBOL_name', ''))
	instance_name = StringName(symbol.get('Instance_Name', ''))
	frame = int(symbol.get('firstFrame', 0))

	var raw_symbol_type: String = symbol.get('symbolType', '')
	match raw_symbol_type:
		'graphic': symbol_type = SymbolType.GRAPHIC
		'movieclip': symbol_type = SymbolType.MOVIE_CLIP
		_: printerr('Unknown symbol type detected %s' % [raw_symbol_type])

	match symbol.get('loop', ''):
		## TODO: Get the other loop names lmao
		'playonce': loop_mode = SymbolLoopMode.ONE_SHOT
		'loop': loop_mode = SymbolLoopMode.LOOP
		_: loop_mode = SymbolLoopMode.LOOP

	super(symbol.get('Matrix3D', {}))


func parse_optimized(input: Dictionary) -> void:
	var symbol: Dictionary = input.get('SI', {})
	name = StringName(symbol.get('SN', ''))
	instance_name = StringName(symbol.get('IN', ''))
	frame = int(symbol.get('FF', 0))

	var raw_symbol_type: String = symbol.get('ST', '')
	match raw_symbol_type:
		'G': symbol_type = SymbolType.GRAPHIC
		# check this for sure
		'MC': symbol_type = SymbolType.MOVIE_CLIP
		_: printerr('Unknown symbol type detected %s' % [raw_symbol_type])

	match symbol.get('LP', ''):
		## TODO: Get the other loop names lmao
		'PO': loop_mode = SymbolLoopMode.ONE_SHOT
		'LP': loop_mode = SymbolLoopMode.LOOP
		_: loop_mode = SymbolLoopMode.LOOP

	# Small conversion because inheritance yucky
	var m3d: Array = symbol.get('M3D', [])
	var m3d_dict: Dictionary = {}
	for i: int in m3d.size():
		m3d_dict.set(i, m3d[i])
	super(m3d_dict)
