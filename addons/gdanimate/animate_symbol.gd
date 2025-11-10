@tool
@icon('animate_symbol.svg')
class_name AnimateSymbol extends Node2D
## Node that lets you play Adobe Animate Texture Atlases
## in Godot.


## The folder path to the atlas that is loaded.
## [br][br][b]Note[/b]: This automatically reloads the atlas when
## changed.
@export_dir var atlas: String:
	set(v):
		atlas = v
		load_atlas(atlas)

@export_tool_button('Cache Atlas', 'Save') var cache_atlas := _cache_atlas

@export_group('Animation')

## The current symbol used by the animation. Empty uses the timeline symbol.
## [br][br][b]Note[/b]: This automatically sets [member frame] to 0 when
## changed. (Resetting the current animation)
@export var symbol: String = '':
	set(v):
		if symbol != v:
			queue_redraw()
		symbol = v
		symbol_changed.emit(v)
		frame = 0
		_timer = 0.0

## The current frame of the animation.
## [br][br][b]Note[/b]: This automatically redraws the entire
## atlas when changed.
@export var frame: int = 0:
	set(v):
		if frame != v:
			queue_redraw()
		frame = v

## Defines what happens when the end of the animation is reached.
## [br][br]Loop loops the animation forever and Play Once just stops.
@export_enum('Loop', 'Play Once') var loop_mode: String = 'Loop'

@export_range(0.0, 10.0, 0.01, 'or_greater') var speed: float = 1.0

@export var offset: Vector2 = Vector2.ZERO:
	set(v):
		if offset != v:
			queue_redraw()
		offset = v

## Keeps track of whether or not the sprite is being animated automatically.
@export var playing: bool = false

var _timeline:
	get:
		if not is_instance_valid(_animation):
			return null
		return _animation.symbol_dictionary.get(symbol, _animation.timeline)

var _collections: Array[SpriteCollection]
var _animation: AtlasAnimation
var _timer: float = 0.0
var _current_transform: Transform2D = Transform2D.IDENTITY

signal finished
signal symbol_changed(symbol: String)


func _process(delta: float) -> void:
	if not is_instance_valid(_animation):
		frame = 0
		return

	if not playing:
		return

	_timer += delta * speed
	while _timer >= 1.0 / _animation.framerate:
		frame += 1
		_timer -= 1.0 / _animation.framerate
		if frame > _timeline.length - 1:
			match loop_mode:
				'Loop':
					frame = 0
				_:
					if playing:
						playing = false
						finished.emit()
					frame = _timeline.length - 1


func _cache_atlas() -> void:
	var parsed := ParsedAtlas.new()
	parsed.collections = _collections
	parsed.animation = _animation

	var atlas_directory := atlas
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()

	var err := ResourceSaver.save(parsed, \
			'%s/Animation.res' % [atlas_directory], ResourceSaver.FLAG_COMPRESS)
	if err != OK:
		printerr(err)


## Loads a new atlas from the specified [param path].
func load_atlas(path: String) -> void:
	_collections.clear()
	_animation = null

	var atlas_directory := path
	if not atlas_directory.get_extension().is_empty():
		atlas_directory = atlas_directory.get_base_dir()

	var parsed_path := '%s/Animation.res' % atlas_directory
	if ResourceLoader.exists(parsed_path):
		var parsed: ParsedAtlas = load(parsed_path)
		_animation = parsed.animation
		_collections = parsed.collections
		frame = 0
		return

	var files := ResourceLoader.list_directory(atlas_directory)
	for file in files:
		if file.begins_with('spritemap') and file.ends_with('.json'):
			var spritemap_string := FileAccess.get_file_as_string('%s/%s' % [atlas_directory, file])
			var spritemap_json: Variant = JSON.parse_string(spritemap_string)
			if spritemap_json == null:
				printerr('Failed to parse %s' % file)
				return
			var sprite_collection := SpriteCollection.load_from_json(
				spritemap_json,
				load('%s/%s.png' % [atlas_directory, file.get_basename()])
			)
			_collections.push_back(sprite_collection)

	var animation_string := FileAccess.get_file_as_string('%s/Animation.json' % [atlas_directory])
	if animation_string.is_empty():
		return

	var animation_json: Variant = JSON.parse_string(animation_string)
	if animation_json == null:
		return
	_animation = AtlasAnimation.load_from_json(animation_json)
	frame = 0


func _draw_symbol(element: Element) -> void:
	if not _animation.symbol_dictionary.has(element.name):
		printerr('Tried to draw invalid symbol "%s"' % [element.name])
		return

	_draw_timeline(_animation.symbol_dictionary.get(element.name), element.frame, element.loop_mode == SymbolElement.SymbolLoopMode.LOOP)


func _draw_sprite(element: Element) -> void:
	draw_set_transform_matrix(_current_transform)
	for collection: SpriteCollection in _collections:
		if not collection.map.has(element.name):
			continue
		var sprite: CollectedSprite = collection.map.get(element.name)
		if is_instance_valid(sprite.custom_texture):
			RenderingServer.canvas_item_add_texture_rect(
				get_canvas_item(),
				Rect2(
					Vector2.ZERO,
					Vector2(sprite.rect.size.y, sprite.rect.size.x)
				),
				sprite.custom_texture,
				false
			)
		else:
			RenderingServer.canvas_item_add_texture_rect_region(
				get_canvas_item(),
				Rect2(Vector2.ZERO, Vector2(sprite.rect.size)),
				collection.texture,
				Rect2(sprite.rect)
			)
		return
	printerr('Tried to draw invalid sprite "%s"' % [element.name])


func _draw_timeline(timeline: Timeline, target_frame: int, loop: bool = false) -> void:
	var layers: Array[Layer] = timeline.layers
	if layers.is_empty():
		return

	var og_frame: int = target_frame
	var layer_transform: Transform2D = _current_transform
	var i: int = layers.size() - 1
	while i >= 0:
		var layer: Layer = layers[i]
		if layer.length <= 0:
			i -= 1
			continue
		if loop:
			target_frame = og_frame % layer.length
		for layer_frame in layer.frames:
			if target_frame < layer_frame.index:
				continue
			if target_frame > layer_frame.index + layer_frame.duration - 1:
				continue
			for element in layer_frame.elements:
				_current_transform = layer_transform
				_current_transform *= element.transform
				match element.type:
					Element.ElementType.SYMBOL:
						_draw_symbol(element)
					Element.ElementType.SPRITE:
						_draw_sprite(element)
			break

		i -= 1


func _draw() -> void:
	RenderingServer.canvas_item_clear(get_canvas_item())

	if not is_instance_valid(_timeline):
		return

	_current_transform = Transform2D.IDENTITY
	if offset != Vector2.ZERO:
		_current_transform = _current_transform.translated(offset)
	_draw_timeline(_timeline, frame)
