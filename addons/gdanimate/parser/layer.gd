class_name Layer extends Resource


@export var name: StringName
@export var frames: Array[LayerFrame] = []
@export var length: int = 0


func _find_next_keyframe(start: LayerFrame) -> LayerFrame:
	var index := frames.find(start)
	if index < frames.size() - 1:
		return frames[index + 1]

	return start


func _fill_keyframes() -> void:
	if frames.is_empty():
		return

	var index: int = 0
	var cursor: LayerFrame = frames[index]
	var next: LayerFrame = _find_next_keyframe(cursor)
	for frame in frames:
		length += frame.duration

	while index < length - 1:
		index += 1
		if next.index - cursor.index > 1:
			var previous := cursor
			cursor = previous.duplicate(true)
			previous.duration = 1
			cursor.index = index
			cursor.duration -= 1
			frames.insert(index, cursor)
			next = _find_next_keyframe(cursor)
		else:
			cursor = next
			next = _find_next_keyframe(cursor)


func parse_unoptimized(input: Dictionary) -> void:
	var raw_frames: Array = input.get('Frames', [])
	for raw_frame: Dictionary in raw_frames:
		var frame := LayerFrame.new()
		frame.index = raw_frame.get('index', -1)
		frame.duration = raw_frame.get('duration', 1)

		var frame_elements: Array = raw_frame.get('elements', [])
		for raw_element: Dictionary in frame_elements:
			var element: Element
			if raw_element.has('SYMBOL_Instance'):
				element = SymbolElement.new()
			elif raw_element.has('ATLAS_SPRITE_instance'):
				element = SpriteElement.new()
			else:
				printerr('Found unknown element type.\n%s' % [raw_element])
				continue

			element.parse_unoptimized(raw_element)
			frame.elements.push_back(element)
		frames.push_back(frame)

	_fill_keyframes()


func parse_optimized(input: Dictionary) -> void:
	var raw_frames: Array = input.get('FR', [])
	for raw_frame: Dictionary in raw_frames:
		var frame := LayerFrame.new()
		frame.index = raw_frame.get('I', -1)
		frame.duration = raw_frame.get('DU', 1)

		var frame_elements: Array = raw_frame.get('E', [])
		for raw_element: Dictionary in frame_elements:
			var element: Element
			if raw_element.has('SI'):
				element = SymbolElement.new()
			elif raw_element.has('ASI'):
				element = SpriteElement.new()
			else:
				printerr('Found unknown element type.\n%s' % [raw_element])
				continue

			element.parse_optimized(raw_element)
			frame.elements.push_back(element)
		frames.push_back(frame)

	_fill_keyframes()
