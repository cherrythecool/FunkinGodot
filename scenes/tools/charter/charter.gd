extends Control


@onready var tracks: Tracks = %tracks
var chart: Chart = null


func _ready() -> void:
	chart = Chart.load_song(&'bopeebo_erect', &'nightmare')
	Conductor.get_bpm_changes(chart.events)

	tracks.load_tracks(&'bopeebo_erect')
	Conductor.target_audio = tracks.player
	tracks.play()
