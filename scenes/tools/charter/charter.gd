extends Control

@onready var conductor: Conductor = %conductor
@onready var tracks: Tracks = %tracks

static var song_data: Dictionary = {"n": null, "d": null}
static var chart: Chart = null

static var previous_song_position: float = 0

var selected_notes:Array[CharterNote] = []
var clipboard:CharterClipboard

@onready var camera: Camera2D = %camera
@onready var grid_parallax: Parallax2D = %grid_parallax

@onready var opponent_grid: Control = %opponent_grid
@onready var opponent_icon_point: Node2D = %opponent_icon
var opponent_icon: Sprite2D = null

@onready var player_grid: Control = %player_grid
@onready var player_icon_point: Node2D = %player_icon
var player_icon: Sprite2D = null

@onready var event_grid: Control = %event_grid

@onready var cursor_note: CharterNote = %cursor_note
@onready var strum_line: ColorRect = %strum_line
@onready var note_group: Node2D = %notes
@onready var separator_group: Node2D = %separators

var rendered_notes: Array[Node] = []

static func load_song(song_name: String, difficulty: String) -> void:
	song_data = {'n': song_name, 'd': difficulty}
	previous_song_position = 0
	chart = Chart.load_song(song_data.n, song_data.d)

func _ready() -> void:
	conductor.reset()

	if chart == null:
		load_song(&'darnell_bf', &'hard')
	conductor.get_bpm_changes(chart.events)
	conductor.raw_time = previous_song_position

	tracks.load_tracks(song_data.n)
	conductor.target_audio = tracks.player
	conductor.calculate_beat()
	#tracks.play()
	_pause_song()

	var assets: SongAssets = load('res://assets/songs/%s/assets.tres' % [song_data.n])
	var temp_player: Character = assets.get_player().instantiate()
	player_icon = load_icon(player_icon_point, temp_player.icon)
	temp_player.free()
	player_icon.flip_h = true

	var temp_opponent: Character = assets.get_opponent().instantiate()
	opponent_icon = load_icon(opponent_icon_point, temp_opponent.icon)
	temp_opponent.free()
	
	reload_notes()
	reload_grid_separator()

func load_icon(point: Node2D, icon_res: Icon) -> Sprite2D:
	if point.has_node(^'icon'):
		point.get_node(^'icon').queue_free()
		point.remove_child(point.get_node(^'icon'))

	var icon: Sprite2D = Icon.create_sprite(icon_res)
	point.add_child(icon)
	return icon
	
func reload_notes() -> void:
	for note: CharterNote in rendered_notes: note.queue_free()
	rendered_notes.clear()
	
	for data: NoteData in chart.notes:
		add_note_object(data)
	for event: EventData in chart.events:
		print(event)
		if (event.time == 0 && event is not BPMChange) || event.time > 0:  # ignore first bpm change so they don't accidentally delete it
			add_event_object(event)

func add_note_object(note_data: NoteData) -> CharterNote:
	var note: CharterNote = load('res://scenes/tools/charter/charter_note.tscn').instantiate()
	note.setup(note_data)
	
	var target_grid: Node = opponent_grid
	if note_data.direction < 4:
		target_grid = player_grid
	
	note.position.x = target_grid.position.x + floor(opponent_grid.grid_size.x * (note_data.direction % 4)) + 23
	note.position.y = opponent_grid.grid_size.y / 2
	note.position.y += conductor.get_time_in_step(note_data.time*1000) * opponent_grid.grid_size.y
	
	rendered_notes.push_back(note)
	note_group.add_child(note)
	return note
	
func add_event_object(event_data: EventData) -> CharterNote:
	var note: CharterNote = load('res://scenes/tools/charter/charter_note.tscn').instantiate()
	note.setup_event(event_data)
	
	note.position.x = event_grid.position.x + 23
	note.position.y = event_grid.grid_size.y / 2
	note.position.y += conductor.get_time_in_step(event_data.time*1000) * event_grid.grid_size.y
	
	rendered_notes.push_back(note)
	note_group.add_child(note)
	return note

func _process(_delta: float) -> void:
	if conductor.raw_time < 0:
		conductor.raw_time = 0
	strum_line.position.y = 192 + conductor.get_time_in_step(conductor.time*1000) * opponent_grid.grid_size.y
	camera.position.y = strum_line.global_position.y
	
	for note: CharterNote in rendered_notes:
		if selected_notes.has(note):
			note.modulate.a = 0.6
		else:
			note.modulate.a = 1
	# make top of grids not looping
	if camera.position.y >= Global.game_size.y:
		grid_parallax.repeat_times = 2
	elif grid_parallax.repeat_times != 1:
		grid_parallax.repeat_times = 1
	
	opponent_icon.scale = Vector2(0.9, 0.9).lerp(Vector2(0.8, 0.8), _icon_lerp())
	player_icon.scale = Vector2(0.9, 0.9).lerp(Vector2(0.8, 0.8), _icon_lerp())
	
	# Optimization????
	var copy_notes_to_clipboard: Callable = func() -> void:
		clipboard = CharterClipboard.new(conductor.raw_time)
		for note: CharterNote in selected_notes:
			if note.is_event:
				clipboard.events.push_back(note.event_data.duplicate_deep())
			else:
				clipboard.notes.push_back(note.data.duplicate_deep())
	
	if Input.is_action_just_pressed("charter_copy"):
		copy_notes_to_clipboard.call()
	
	if Input.is_action_just_pressed("charter_paste"):
		selected_notes.clear()
		if clipboard != null:
			for note_data: NoteData in clipboard.notes:
				note_data.time += conductor.raw_time - clipboard.time
				chart.notes.push_back(note_data)
				selected_notes.push_back(add_note_object(note_data))
			for event_data: EventData in clipboard.events:
				event_data.time += conductor.raw_time - clipboard.time
				chart.events.push_back(event_data)
				selected_notes.push_back(add_event_object(event_data))
	
	if Input.is_action_just_pressed("charter_select_all"):
		selected_notes.clear()
		for note: CharterNote in rendered_notes:
			selected_notes.push_back(note)
	if Input.is_action_just_pressed("charter_select_all_note"):
		selected_notes.clear()
		for note: CharterNote in rendered_notes:
			if !note.is_event:
				selected_notes.push_back(note)
	if Input.is_action_just_pressed("charter_select_all_event"):
		selected_notes.clear()
		for note: CharterNote in rendered_notes:
			if note.is_event:
				selected_notes.push_back(note)
	if Input.is_action_just_pressed("charter_cut"):
		copy_notes_to_clipboard.call()
		for note: CharterNote in selected_notes:
			remove_note(note)
	
func reload_grid_separator() -> void:
	for sep: Node2D in separator_group.get_children(): sep.queue_free()
	print(tracks.get_length() / conductor.measure_delta)
	for sec: int in int(tracks.get_length() / conductor.measure_delta):
		var separator: Node = load('uid://b3mjv4e8vba4d').instantiate()
		separator.position.y =  conductor.get_time_in_step((conductor.measure_delta * sec) * 1000) * opponent_grid.grid_size.y
		separator_group.add_child(separator)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed && !event.echo:
			if event.keycode == KEY_SPACE:
				if tracks.playing: _pause_song()
				else: _resume_song()
			if event.keycode == KEY_A:
				_pause_song()
				conductor.raw_time = (int(conductor.measure) - 1) * conductor.measure_delta
				conductor.calculate_beat()
			if event.keycode == KEY_D:
				_pause_song()
				conductor.raw_time = (int(conductor.measure) + 1) * conductor.measure_delta
				conductor.calculate_beat()
				
			if event.keycode == KEY_E:
				for note: CharterNote in selected_notes:
					if !note.is_event:
						note.length += conductor.step_delta
						note.data.length = note.length
			if event.keycode == KEY_Q:
				for note: CharterNote in selected_notes:
					if !note.is_event:
						note.length -= conductor.step_delta
						note.data.length = note.length
				
			if event.keycode == KEY_ENTER:
				_pause_song()
				previous_song_position = conductor.time
				
				Game.playlist.clear()
				Game.song = song_data.n
				Game.difficulty = song_data.d
				Game.mode = Game.PlayMode.CHARTER
				Game.chart = chart
				if Input.is_key_label_pressed(KEY_SHIFT):
					Game.initial_song_time = conductor.time
				SceneManager.switch_to(load('res://scenes/game/game.tscn'))
	if event is InputEventMouseMotion:
		if get_local_mouse_position().y >= 192:
			if opponent_grid.position.x < get_local_mouse_position().x && player_grid.position.x + player_grid.grid_size.x * player_grid.columns >= get_local_mouse_position().x:
				cursor_note.visible = true
				cursor_note.lane = absi(floor((get_local_mouse_position().x - opponent_grid.position.x) / opponent_grid.grid_size.x))
				cursor_note.is_event = false
				cursor_note.position.x = opponent_grid.position.x + (absi(cursor_note.lane) * opponent_grid.grid_size.x) + 23
			elif event_grid.position.x < get_local_mouse_position().x && event_grid.position.x + event_grid.grid_size.x >= get_local_mouse_position().x:
				cursor_note.position.x = event_grid.position.x + 23
				cursor_note.is_event = true
				cursor_note.visible = true
		else:
			cursor_note.visible = false
		
		cursor_note.position.y = floor(get_local_mouse_position().y / opponent_grid.grid_size.y) * opponent_grid.grid_size.y + 34
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				conductor.raw_time -= 0.01
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				conductor.raw_time += 0.01
			if event.button_index == MOUSE_BUTTON_RIGHT:
				for note: CharterNote in rendered_notes:
					if note.rect.get_rect().has_point(note.get_local_mouse_position()):
						remove_note(note)
			if event.button_index == MOUSE_BUTTON_LEFT:
				for note: CharterNote in rendered_notes:
					if note.rect.get_rect().has_point(note.get_local_mouse_position()):
						if !Input.is_key_label_pressed(KEY_SHIFT):
							selected_notes.clear()
						if !selected_notes.has(note):
							selected_notes.push_back(note)
						return
				if cursor_note.visible:
					selected_notes.clear()
					if cursor_note.is_event:
						var event_data: EventData = CameraPan.new((cursor_note.position.y / event_grid.grid_size.y - 4.7555) * conductor.step_delta, CameraPan.Side.PLAYER)
						chart.events.push_back(event_data)
						selected_notes.push_back(add_event_object(event_data))
						
						Chart.sort_chart_events(chart)
					else:
						var note_data: NoteData = NoteData.new()
						var temp_lane: int = cursor_note.lane
						if temp_lane > 3:
							temp_lane = temp_lane % 4
						else:
							temp_lane += 4
						note_data.direction = temp_lane
						# weirdly offseted for some reason???
						note_data.time = (cursor_note.position.y / opponent_grid.grid_size.y - 4.7555) * conductor.step_delta
					
						chart.notes.push_back(note_data)
						selected_notes.push_back(add_note_object(note_data))
						
						Chart.sort_chart_notes(chart)
						Chart.remove_stacked_notes(chart)
	if event is InputEventPanGesture: # trackpad gesture
		_pause_song()
		conductor.raw_time -= event.delta.y/8
		
# ease out sine
func _icon_ease(x: float) -> float:
	return sin((x * PI) / 2.0)
func _icon_lerp() -> float:
	return _icon_ease(conductor.beat - floorf(conductor.beat))

func remove_note(note: CharterNote) -> void:
	if note.is_event:
		chart.events.erase(note.event_data)
	else:
		chart.notes.erase(note.data)
	rendered_notes.erase(note)
	note.queue_free()

func _pause_song() -> void:
	conductor.active = false
	tracks.stop()
	
func _resume_song() -> void:
	tracks.play(conductor.time)
	conductor.active = true
	conductor.calculate_beat()
