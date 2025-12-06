class_name Chart extends Resource


var notes: Array[NoteData] = []
var events: Array[EventData] = []
var scroll_speed: float = 1.0


static func load_song(name: StringName, difficulty: StringName) -> Chart:
	var start: int = Time.get_ticks_usec()
	name = name.to_lower()
	difficulty = difficulty.to_lower()

	var chart: Chart = null
	var base_path: String = 'res://assets/songs/%s' % name
	chart = try_legacy(base_path, difficulty)
	if is_instance_valid(chart):
		_print_time_elapsed(start)
		return chart

	chart = try_fnfc(base_path, difficulty)
	if is_instance_valid(chart):
		_print_time_elapsed(start)
		return chart

	printerr('Chart of song %s with difficulty %s not found.' % [name, difficulty])
	return chart


static func _print_time_elapsed(start: int) -> void:
	print('Loaded in %.3fms.' % [float(Time.get_ticks_usec() - start) / 1000.0])


static func sort_chart_notes(chart: Chart) -> void:
	chart.notes.sort_custom(func(a: NoteData, b: NoteData) -> bool:
		return a.time < b.time)


static func sort_chart_events(chart: Chart) -> void:
	chart.events.sort_custom(func(a: EventData, b: EventData) -> bool:
		return a.time < b.time)


static func remove_stacked_notes(chart: Chart) -> int:
	var index: int = 0
	var last_note: NoteData = null
	var stacked_notes: int = 0

	while (not chart.notes.is_empty()) and index < chart.notes.size():
		var note: NoteData = chart.notes[index]
		if not is_instance_valid(last_note):
			index += 1
			last_note = note
			continue

		if last_note.direction == note.direction and \
				absf(last_note.time - note.time) <= 25.0 / 1000.0:
			chart.notes.remove_at(index)
			stacked_notes += 1
			continue

		last_note = note
		index += 1

	return stacked_notes


static func try_legacy(base_path: String, difficulty: StringName) -> Chart:
	var legacy_exists: bool = ResourceLoader.exists('%s/charts/%s.json' % [base_path, difficulty])
	if not legacy_exists:
		return null

	var path: String = '%s/charts/%s.json' % [base_path, difficulty]
	var funkin: FunkinLegacyChart = FunkinLegacyChart.new()
	funkin.json = load(path).data
	if 'codenameChart' in funkin.json and funkin.json.codenameChart == true:
		return CodenameChart.parse(base_path, funkin.json)

	if funkin.json.song is Dictionary:
		funkin.scroll_speed = funkin.json.song.get('speed', 1.0)
	else:
		funkin.scroll_speed = funkin.json.get('speed', 1.0)

	var extra_events: Array[EventData] = []
	var events_path: String = '%s/charts/events.json' % [base_path]
	if ResourceLoader.exists(events_path):
		var events_json: String = FileAccess.get_file_as_string(events_path)
		var data: Dictionary = JSON.parse_string(events_json)
		if data.song is Dictionary:
			extra_events.append_array(FunkinLegacyChart.parse_events(data.song))
		else:
			extra_events.append_array(FunkinLegacyChart.parse_events(data))

	var chart: Chart = funkin.parse()
	chart.events.append_array(extra_events)
	sort_chart_events(chart)
	return chart


static func try_fnfc(base_path: String, difficulty: StringName) -> Chart:
	var fnfc_exists: bool = ResourceLoader.exists('%s/charts/chart.json' % [base_path]) and \
			(ResourceLoader.exists('%s/charts/meta.json' % [base_path]) or ResourceLoader.exists('%s/charts/metadata.json' % [base_path]))
	if not fnfc_exists:
		return null

	var fnfc: FNFCChart = FNFCChart.new()
	var chart_path: String = '%s/charts/chart.json' % [base_path]
	fnfc.json_chart = load(chart_path).data

	var meta_path: String = '%s/charts/meta.json' % [base_path]
	if not ResourceLoader.exists(meta_path):
		meta_path = '%s/charts/metadata.json' % [base_path]
	var meta_data: String = FileAccess.get_file_as_string(meta_path)
	fnfc.json_meta = JSON.parse_string(meta_data)

	if "scrollSpeed" in fnfc.json_chart:
		if fnfc.json_chart.scrollSpeed is float:
			fnfc.scroll_speed = fnfc.json_chart.scrollSpeed
		else:
			if fnfc.json_chart.scrollSpeed.has(difficulty.to_lower()):
				fnfc.scroll_speed = fnfc.json_chart.scrollSpeed.get(difficulty.to_lower(), 1.0)
			else:
				fnfc.scroll_speed = fnfc.json_chart.scrollSpeed.get('default', 1.0)

	return fnfc.parse(difficulty)
