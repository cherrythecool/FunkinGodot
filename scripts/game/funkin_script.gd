class_name FunkinScript extends Node


var game: Game

var player: Character:
	get:
		if is_instance_valid(game):
			return game.player
		return null

var opponent: Character:
	get:
		if is_instance_valid(game):
			return game.opponent
		return null

var spectator: Character:
	get:
		if is_instance_valid(game):
			return game.spectator
		return null

var stage: Stage:
	get:
		if is_instance_valid(game):
			return game.stage
		return null

var player_field: NoteField
var opponent_field: NoteField

var camera: Camera2D


func _ready() -> void:
	Conductor.beat_hit.connect(_on_beat_hit)
	Conductor.step_hit.connect(_on_step_hit)
	Conductor.measure_hit.connect(_on_measure_hit)

	if is_instance_valid(Game.instance):
		game = Game.instance

		player_field = game.player_field
		opponent_field = game.opponent_field

		camera = game.camera
		game.song_start.connect(_on_song_start)
		game.event_prepare.connect(_on_event_prepare)
		game.event_hit.connect(_on_event_hit)
		game.ready_post.connect(_ready_post)
		game.process_post.connect(_process_post)


func _ready_post() -> void:
	pass


func _process_post(_delta: float) -> void:
	pass


func _on_beat_hit(_beat: int) -> void:
	pass


func _on_step_hit(_step: int) -> void:
	pass


func _on_measure_hit(_measure: int) -> void:
	pass


func _on_song_start() -> void:
	pass


func _on_event_prepare(_event: EventData) -> void:
	pass


func _on_event_hit(_event: EventData) -> void:
	pass
