class_name FNFCChart extends Resource


var json_chart: Dictionary
var json_meta: Dictionary
var scroll_speed: float = 1.0


func parse(difficulty: StringName) -> Chart:
	var chart: Chart = Chart.new()
	chart.scroll_speed = scroll_speed
	if not json_chart.notes.has(difficulty):
		printerr("FNFC Chart did not have difficulty of \"%s\"!" % difficulty)
		return null

	if json_chart.has("events"):
		for event: Dictionary in json_chart.get("events"):
			if event.get("e") == "FocusCamera":
				# jesus christ focus camera
				if event.get("v") is Dictionary:
					var values: Dictionary = event.get("v", {})
					chart.events.push_back(
						CameraPan.new(
							float(event.get("t") / 1000.0),
							int(values.get("char", 0)),
							values.get("ease", "CLASSIC"),
							float(values.get("duration", 32.0)),
							Vector2(
								float(values.get("x", 0.0)),
								float(values.get("y", 0.0)),
							)
						)
					)
				else:
					chart.events.push_back(CameraPan.new(float(event.get("t") / 1000.0),
							int(event.get("v"))))
			else:
				chart.events.push_back(DynamicEvent.new(event.get("e"),
						float(event.get("t") / 1000.0), event.get("v")))

	# sucky fix but this happens more than once so
	if not chart.events.is_empty() and chart.events[0] is CameraPan:
		chart.events[0].time = floorf(chart.events[0].time)
	
	var found_starter: bool = false
	for event: EventData in chart.events:
		if event is CameraPan and event.time <= 0.0:
			found_starter = true
			break
	
	if not found_starter:
		chart.events.push_front(CameraPan.new())

	for note: Dictionary in json_chart.notes.get(difficulty):
		var note_data: NoteData = NoteData.new()
		note_data.time = note.get("t") / 1000.0
		## TODO: Fix the stupid beat i"m too lazy rn cuz its not used uwu
		note_data.beat = note_data.time
		note_data.direction = note.get("d")
		if note.has("l"):
			note_data.length = clampf(note.get("l") / 1000.0, 0.0, INF)

		note_data.type = note.get("k", &"default")
		chart.notes.push_back(note_data)

	for change: Dictionary in json_meta.get("timeChanges", []):
		chart.events.push_back(BPMChange.new(maxf(change.get("t") / 1000.0, 0.0),
				float(change.get("bpm"))))

	Chart.sort_chart_notes(chart)
	var stacked_notes: int = Chart.remove_stacked_notes(chart)
	print("Loaded FNFCChart(%s) with %s stacked notes detected." % [
		"%s/%s" % [json_meta.get("songName", "Unknown"), difficulty], stacked_notes
	])

	return chart
