class_name CodenameChart extends Resource


static func parse(base_path: String, data: Dictionary) -> Chart:
	var meta_path: String = '%s/charts/meta.json' % [base_path]
	if not ResourceLoader.exists(meta_path):
		printerr('Codename Chart missing meta at path "%s"' % [meta_path])
		return null

	var raw_meta: String = FileAccess.get_file_as_string(meta_path)
	var meta: Dictionary = JSON.parse_string(raw_meta)

	var chart: Chart = Chart.new()
	Game.scroll_speed = data.get('scrollSpeed', 1.0)
	chart.events.push_back(BPMChange.new(0.0, meta.get('bpm', 120.0)))
	chart.events.push_back(CameraPan.new(0.0, CameraPan.Side.OPPONENT))

	var sides: Array = []
	var strumlines: Array = data.strumLines
	for strumline: Dictionary in strumlines:
		var character: String = strumline.position
		match character:
			'boyfriend':
				sides.append(CameraPan.Side.PLAYER)
			'girlfriend':
				sides.append(CameraPan.Side.GIRLFRIEND)
			_:
				sides.append(CameraPan.Side.OPPONENT)

		var notes: Array = strumline.notes
		for note: Dictionary in notes:
			var note_data: NoteData = NoteData.new()
			note_data.time = float(note.time) / 1000.0
			## TODO: implement beats lmao
			note_data.beat = 0.0
			note_data.direction = int(note.id)
			if character != 'boyfriend':
				note_data.direction += 4

			note_data.length = clampf(float(note.sLen) / 1000.0, 0.0, INF)
			if note.type != 0:
				note_data.type = str(note.type)
			else:
				note_data.type = &'default'

			chart.notes.push_back(note_data)

	Chart.sort_chart_notes(chart)
	var stacked_notes: int = Chart.remove_stacked_notes(chart)
	print('Loaded CodenameChart(%s) with %s stacked notes detected.' % [
		meta.name, stacked_notes
	])

	for event: Dictionary in data.events:
		var name: String = event.name
		var params: Array = event.params
		var time: float = event.time / 1000.0
		match name:
			'Camera Movement':
				chart.events.append(CameraPan.new(time, sides[params[0]]))
			'BPM Change':
				chart.events.append(BPMChange.new(time, params[0]))
			_:
				chart.events.append(DynamicEvent.new(name, time, params))

	return chart
