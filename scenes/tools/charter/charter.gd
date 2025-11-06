extends Control


@onready var tracks: Tracks = %tracks
var chart: Chart = null

@onready var opponent_grid: Control = %opponent_grid
@onready var opponent_icon_point: Node2D = %opponent_icon
var opponent_icon: Sprite2D = null

@onready var player_grid: Control = %player_grid
@onready var player_icon_point: Node2D = %player_icon
var player_icon: Sprite2D = null

@onready var strum_line: ColorRect = %strum_line
var rendered_notes: Array[Node] = []

func _ready() -> void:
	Conductor.reset()
	chart = Chart.load_song(&'bopeebo_erect', &'nightmare')
	Conductor.get_bpm_changes(chart.events)
	Conductor.calculate_beat()

	tracks.load_tracks(&'bopeebo_erect')
	Conductor.target_audio = tracks.player
	tracks.play()

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
	
	note.position.x = floor(target_grid.grid_size.x * (note_data.direction % 4)) + 23
	note.position.y = target_grid.grid_size.y / 2
	note.position.y += Conductor.get_time_in_step(note_data.time*1000) * target_grid.grid_size.y
	
	rendered_notes.push_back(note)
	target_grid.add_child(note)

func _process(delta: float) -> void:
	strum_line.global_position.y = 192 + Conductor.get_time_in_step(Conductor.time*1000) * opponent_grid.grid_size.y
	$camera.global_position.y = strum_line.global_position.y
	
	for note in rendered_notes:
		if note.data.time <= Conductor.time:
			note.modulate.a = 0.5
		else:
			note.modulate.a = 1
