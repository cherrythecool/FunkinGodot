extends Control


@onready var tracks: Tracks = %tracks
var chart: Chart = null

@onready var opponent_grid: Control = %opponent_grid
@onready var opponent_icon_point: Node2D = %opponent_icon
var opponent_icon: Sprite2D = null

@onready var player_grid: Control = %player_grid
@onready var player_icon_point: Node2D = %player_icon
var player_icon: Sprite2D = null


func _ready() -> void:
	chart = Chart.load_song(&'bopeebo_erect', &'nightmare')
	Conductor.get_bpm_changes(chart.events)

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


func load_icon(point: Node2D, icon_res: Icon) -> Sprite2D:
	if point.has_node(^'icon'):
		point.get_node(^'icon').queue_free()
		point.remove_child(point.get_node(^'icon'))

	var icon: Sprite2D = Icon.create_sprite(icon_res)
	point.add_child(icon)
	return icon
