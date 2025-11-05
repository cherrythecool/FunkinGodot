extends Control


@onready var tracks: Tracks = %tracks
var chart: Chart = null

@onready var opponent_grid: Control = %opponent_grid
@onready var opponent_icon_point: Node2D = %opponent_icon
var opponent_icon: Sprite2D = null

@onready var player_grid: Control = %player_grid
@onready var player_icon_point: Node2D = %player_icon
var player_icon: Sprite2D = null

@onready var dummy_arrow: ColorRect = $%dummy_arrow

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
	for child in opponent_grid.get_children(): child.queue_free()
	for child in player_grid.get_children(): child.queue_free()
	
	for data: NoteData in chart.notes:
		add_note_object(data)

func add_note_object(note_data: NoteData) -> void:
	var note: Node = load('res://scenes/tools/charter/charter_note.tscn').instantiate()
	note.setup(note_data)
	
	var target_grid: Node = opponent_grid
	if note_data.direction < 4:
		target_grid = player_grid
	
	note.position.x = floor(target_grid.grid_size.x * (note_data.direction % 4)) + 22
	note.position.y = target_grid.grid_size.y / 2
	note.position.y += Conductor.get_time_in_step(note_data.time*1000) * target_grid.grid_size.y
	
	rendered_notes.push_back(note)
	target_grid.add_child(note)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if player_grid.get_rect().has_point(event.position):
			dummy_arrow.visible = true
			dummy_arrow.position.x = (floor(event.position.x / opponent_grid.grid_size.x) * opponent_grid.grid_size.x) + 5
			dummy_arrow.position.y = floor(event.position.y / opponent_grid.grid_size.y) * opponent_grid.grid_size.y
		if opponent_grid.get_rect().has_point(event.position):
			dummy_arrow.visible = true
			dummy_arrow.position.x = (floor(event.position.x / opponent_grid.grid_size.x) * opponent_grid.grid_size.x) + 15
			dummy_arrow.position.y = floor(event.position.y / player_grid.grid_size.y) * player_grid.grid_size.y
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var note_data = NoteData.new()
		note_data.direction = floor(event.position.x / opponent_grid.grid_size.x)
		note_data.time = ((dummy_arrow.position.y / opponent_grid.grid_size.y) * Conductor.step_delta) * 1000
		print(note_data)
