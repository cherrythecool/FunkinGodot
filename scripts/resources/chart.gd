class_name Chart extends Resource


var notes: Array[NoteData] = []
var events: Array[EventData] = []


func _to_string() -> String:
	return 'Chart(notes: %s, events: %s)' % [notes, events]


static func load_song(name: StringName, difficulty: StringName) -> Chart:
	var start: int = Time.get_ticks_usec()
	
	name = name.to_lower()
	difficulty = difficulty.to_lower()
	
	var chart: Chart = null
	var base_path: String = 'res://assets/songs/%s' % name
	
	chart = _try_legacy(base_path, difficulty)
	if is_instance_valid(chart):
		_print_time_elapsed(start)
		return chart
	
	chart = _try_fnfc(base_path, difficulty)
	if is_instance_valid(chart):
		_print_time_elapsed(start)
		return chart
	
	printerr('Chart of song %s with difficulty %s not found.' % [name, difficulty])
	return chart


static func _print_time_elapsed(start: int) -> void:
	print('Loaded in %.3fms.' % [float(Time.get_ticks_usec() - start) / 1000.0])


static func sort_chart_notes(chart: Chart) -> void:
	chart.notes.sort_custom(func(a: NoteData, b: NoteData):
		return a.time < b.time)


static func sort_chart_events(chart: Chart) -> void:
	chart.events.sort_custom(func(a: EventData, b: EventData):
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
				absf(last_note.time - note.time) <= 0.001:
			chart.notes.remove_at(index)
			stacked_notes += 1
			continue
		
		last_note = note
		index += 1
	
	return stacked_notes


static func _try_legacy(base_path: String, difficulty: StringName) -> Chart:
	var legacy_exists: bool = ResourceLoader.exists('%s/charts/%s.json' % [base_path, difficulty])
	if legacy_exists:
		var path := '%s/charts/%s.json' % [base_path, difficulty]
		var funkin := FunkinLegacyChart.new()
		var json := FileAccess.get_file_as_string(path)
		funkin.json = JSON.parse_string(json)
		if funkin.json.song is Dictionary:
			Game.scroll_speed = funkin.json.song.get('speed', 1.0)
		else:
			Game.scroll_speed = funkin.json.get('speed', 1.0)
		
		var extra_events: Array[EventData] = []
		var events_path := '%s/charts/events.json' % [base_path]
		if ResourceLoader.exists(events_path):
			var events_json := FileAccess.get_file_as_string(events_path)
			var data: Dictionary = JSON.parse_string(events_json)
			if data.song is Dictionary:
				extra_events.append_array(FunkinLegacyChart.parse_events(data.song))
			else:
				extra_events.append_array(FunkinLegacyChart.parse_events(data))
		
		var chart := funkin.parse()
		chart.events.append_array(extra_events)
		sort_chart_events(chart)
		return chart
	
	return null


static func _try_fnfc(base_path: String, difficulty: StringName) -> Chart:
	var fnfc_exists: bool = ResourceLoader.exists('%s/charts/chart.json' % [base_path]) and \
			ResourceLoader.exists('%s/charts/meta.json' % [base_path])
	
	if fnfc_exists:
		var path_chart := '%s/charts/chart.json' % [base_path]
		var path_meta := '%s/charts/meta.json' % [base_path]
		var fnfc := FNFCChart.new()
		var json_chart := FileAccess.get_file_as_string(path_chart)
		var json_meta := FileAccess.get_file_as_string(path_meta)
		fnfc.json_chart = JSON.parse_string(json_chart)
		fnfc.json_meta = JSON.parse_string(json_meta)
		
		if fnfc.json_chart.scrollSpeed is float:
			Game.scroll_speed = fnfc.json_chart.scrollSpeed
		else:
			if fnfc.json_chart.scrollSpeed.has(difficulty.to_lower()):
				Game.scroll_speed = fnfc.json_chart.scrollSpeed.get(difficulty.to_lower(), 1.0)
			else:
				Game.scroll_speed = fnfc.json_chart.scrollSpeed.get('default', 1.0)
		
		return fnfc.parse(difficulty)
	
	return null
