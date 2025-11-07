extends Control


@onready var tracks: Tracks = %tracks
static var chart: Chart = null

static var previous_song_position: float = 0

@onready var camera: Camera2D = %camera
@onready var grid_parallax: Parallax2D = %grid_parallax

@onready var opponent_grid: Control = %opponent_grid
@onready var opponent_icon_point: Node2D = %opponent_icon
var opponent_icon: Sprite2D = null

@onready var player_grid: Control = %player_grid
@onready var player_icon_point: Node2D = %player_icon
var player_icon: Sprite2D = null

@onready var strum_line: ColorRect = %strum_line
@onready var notes_group: Node2D = %notes

var note_data_lookup: Dictionary = {}
var rendered_notes: Array[Node] = []

func _ready() -> void:
	Conductor.reset()
	if chart == null:
		chart = Chart.load_song(&'bopeebo_erect', &'nightmare')
	Conductor.get_bpm_changes(chart.events)
	Conductor.active = false
	Conductor.time = previous_song_position

	tracks.load_tracks(&'bopeebo_erect')
	Conductor.target_audio = tracks.player
	#tracks.play()

	var assets: SongAssets = load('res://assets/songs/%s/assets.tres' % [&'bopeebo_erect'])
	var temp_player: Character = assets.get_player().instantiate()
	player_icon = load_icon(player_icon_point, temp_player.icon)
	temp_player.free()
	player_icon.flip_h = true

	var temp_opponent: Character = assets.get_opponent().instantiate()
	opponent_icon = load_icon(opponent_icon_point, temp_opponent.icon)
	temp_opponent.free()
	
	reload_note_render()

func load_icon(point: Node2D, icon_res: Icon) -> Sprite2D:
	if point.has_node(^'icon'):
		point.get_node(^'icon').queue_free()
		point.remove_child(point.get_node(^'icon'))

	var icon: Sprite2D = Icon.create_sprite(icon_res)
	point.add_child(icon)
	return icon
	
func reload_note_render() -> void:
	for note in rendered_notes: note.queue_free()
	rendered_notes.clear()
	
	for data: NoteData in chart.notes:
		add_note_object(data)

func add_note_object(note_data: NoteData) -> void:
	var note: Node = load('res://scenes/tools/charter/charter_note.tscn').instantiate()
	note.setup(note_data)
	
	var target_grid: Node = opponent_grid
	if note_data.direction < 4:
		target_grid = player_grid
	
	note.position.x = target_grid.global_position.x + floor(target_grid.grid_size.x * (note_data.direction % 4)) + 23
	note.position.y = target_grid.grid_size.y / 2
	note.position.y += Conductor.get_time_in_step(note_data.time*1000) * target_grid.grid_size.y
	
	rendered_notes.push_back(note)
	notes_group.add_child(note)
	note_data_lookup.set(note, note_data)

func _process(delta: float) -> void:
	if Conductor.time < 0:
		Conductor.time = 0
	strum_line.global_position.y = 192 + Conductor.get_time_in_step(Conductor.time*1000) * opponent_grid.grid_size.y
	camera.position.y = strum_line.global_position.y
	
	for note in rendered_notes:
		if note.data.time <= Conductor.time:
			note.modulate.a = 0.5
		else:
			note.modulate.a = 1
	# make top of grids not looping
	if camera.position.y >= Global.game_size.y:
		grid_parallax.repeat_times = 2
	elif grid_parallax.repeat_times != 1:
		grid_parallax.repeat_times = 1
	
	opponent_icon.scale = Vector2(0.9, 0.9).lerp(Vector2(0.8, 0.8), _icon_lerp())
	player_icon.scale = Vector2(0.9, 0.9).lerp(Vector2(0.8, 0.8), _icon_lerp())

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed && !event.echo:
			if event.keycode == KEY_SPACE:
				if tracks.playing: _pause_song()
				else: _resume_song()
			if event.keycode == KEY_ENTER:
				_pause_song()
				previous_song_position = Conductor.time
				
				Game.playlist.clear()
				Game.song = &"bopeebo_erect"
				Game.difficulty = &"nightmare"
				Game.mode = Game.PlayMode.CHARTER
				Game.chart = chart
				if Input.is_key_label_pressed(KEY_SHIFT):
					Game.initial_song_time = Conductor.time
				SceneManager.switch_to(load('res://scenes/game/game.tscn'))
		
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Conductor.time -= 0.01
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Conductor.time += 0.01
			if event.button_index == MOUSE_BUTTON_RIGHT:
				for note in rendered_notes:
					if note.rect.get_rect().has_point(note.get_local_mouse_position()):
						chart.notes.erase(note_data_lookup.get(note))
						rendered_notes.erase(note)
						note.queue_free()
	if event is InputEventPanGesture: # trackpad gesture
		Conductor.time -= event.delta.y/10
# ease out sine
func _icon_ease(x: float) -> float:
	return sin((x * PI) / 2.0)
func _icon_lerp() -> float:
	return _icon_ease(Conductor.beat - floorf(Conductor.beat))


func _pause_song() -> void:
	Conductor.active = false
	tracks.stop()
	
func _resume_song() -> void:
	tracks.play(Conductor.time)
	Conductor.active = true
	Conductor.calculate_beat()
