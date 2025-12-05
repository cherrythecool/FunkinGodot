class_name Game extends Node


static var song: StringName = &"bopeebo"
static var difficulty: StringName = &"hard"
static var chart: Chart = null
static var mode: PlayMode = PlayMode.FREEPLAY
static var exit_scene: String = ""

static var instance: Game = null
static var playlist: Array[GamePlaylistEntry] = []

var persistent_camera_position: bool = true
var events_index: int = 0

static var initial_song_time: float = 0

var pause_menu: PackedScene

@onready var rating_calculator: RatingCalculator = %rating_calculator
@onready var conductor: Conductor = %conductor
@onready var tracks: Tracks = %tracks
@onready var scripts: Scripts = %scripts

@onready var hud_layer: CanvasLayer = %hud_layer
var hud: Node
var player_field: NoteField = null
var opponent_field: NoteField = null

var song_started: bool = false
var save_score: bool = true

@onready var stage_container: Node2D = $stage
@onready var characters_container: Node2D = $characters

## Each note type is stored here for use in any note field.
var note_types: Dictionary[StringName, PackedScene] = {}

var playing: bool = true
var scroll_speed: float = 3.3:
	set(v):
		scroll_speed = v
		scroll_speed_changed.emit()

var assets: SongAssets
var metadata: SongMetadata

var player: Character
var opponent: Character
var spectator: Character
var stage: Stage

var health: float = 50.0
var score: int = 0
var misses: int = 0
var combo: int = 0
var accuracy: float = 0.0:
	get:
		if is_instance_valid(rating_calculator):
			return rating_calculator.accuracy

		return 0.0
var rank: StringName:
	get:
		if is_instance_valid(rating_calculator):
			return rating_calculator.rank

		return &"N/A"

var skin: HUDSkin

signal hud_setup
signal ready_post
signal process_post(delta: float)
signal song_start
signal event_prepare(event: EventData)
signal event_hit(event: EventData)
signal song_finished
signal song_exited
signal scroll_speed_changed
signal died
signal botplay_changed(botplay: bool)
@warning_ignore("unused_signal") signal unpaused


func _ready() -> void:
	if not is_instance_valid(instance):
		instance = self
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.use_accumulated_input = false
	GlobalAudio.music.stop()
	tracks.load_tracks(song)
	tracks.finished.connect(finish_song.bind(false, false))

	load_chart()
	reset_conductor()

	load_assets()
	load_from_assets()
	setup_hud()

	scripts.load_scripts(song)
	load_events()
	ready_post.emit()


func _exit_tree() -> void:
	if instance == self:
		instance = null

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.use_accumulated_input = true


func _process(delta: float) -> void:
	_process_post.call_deferred(delta)

	if not playing:
		return

	if health <= 0.0:
		died.emit()
		Gameover.character_path = player.death_character
		Gameover.character_position = player.global_position
		SceneManager.switch_to(load("uid://c05dah5aarqg8"), false)
		return

	if is_instance_valid(tracks) and not song_started:
		if conductor.raw_time >= 0.0 and conductor.active and not tracks.playing:
			tracks.play()
			conductor.target_audio = tracks.player
			song_start.emit()
			song_started = true
			
			if initial_song_time > 0:
				skip_to(initial_song_time)
				initial_song_time = 0

	while events_index < chart.events.size() and \
			conductor.time >= chart.events[events_index].time:
		var event: EventData = chart.events[events_index]
		event_hit.emit(event)
		events_index += 1


func _process_post(delta: float) -> void:
	process_post.emit(delta)


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_echo():
		return
	if not playing:
		return
	if event.is_action(&"ui_cancel"):
		finish_song(true)
	if event.is_action(&"pause_game"):
		var menu: CanvasLayer = pause_menu.instantiate()
		add_child(menu)
		process_mode = Node.PROCESS_MODE_DISABLED
		conductor.active = false
	
	if event.is_action(&"toggle_botplay") and is_instance_valid(player_field):
		save_score = false
		player_field.takes_input = not player_field.takes_input

		for receptor: Receptor in player_field.receptors:
			receptor.takes_input = player_field.takes_input
			receptor.automatically_play_static = not player_field.takes_input
		botplay_changed.emit(not player_field.takes_input)
	
	if not OS.is_debug_build():
		return
	if event.is_action(&"skip_time"):
		save_score = false
		tracks.set_playback_position(conductor.raw_time + 10.0)
		conductor.raw_time += 10.0
		player_field.try_spawning(true)
		opponent_field.try_spawning(true)


func _on_beat_hit(_beat: int) -> void:
	if is_instance_valid(player):
		player.dance()
	if is_instance_valid(opponent):
		opponent.dance()
	if is_instance_valid(spectator):
		spectator.dance()


func _on_note_miss(note: Note) -> void:
	rating_calculator.add_hit(note.hit_window, note.hit_window)
	health = clampf(health - 2.0, 0.0, 100.0)
	misses += 1
	score -= 10
	combo = 0


func _on_note_hit(_note: Note) -> void:
	combo += 1


func finish_song(force: bool = false, sound: bool = true) -> void:
	if not playing:
		return
	song_finished.emit()
	if force:
		save_score = false

	playing = false
	if save_score:
		var current_score: Dictionary = Scores.get_score(song, difficulty)
		if str(current_score.get("score", "N/A")) == "N/A" or score > current_score.get("score"):
			Scores.set_score(song, difficulty, {
				"score": score,
				"misses": misses,
				"accuracy": accuracy,
				"rank": rank
			})

	if not (playlist.is_empty() or force):
		var new_song: StringName = playlist[0].name
		var new_difficulty: StringName = playlist[0].difficulty
		chart = Chart.load_song(new_song, new_difficulty)

		if not is_instance_valid(chart):
			var json_path: String = (
				"res://assets/songs/%s/charts/%s.json"
				% [new_song, new_difficulty.to_lower()]
			)
			printerr("Song at path %s doesn\'t exist!" % json_path)
			GlobalAudio.get_player("MENU/CANCEL").play()
			song_exited.emit()
			SceneManager.switch_to(load("uid://b7fwxsepnt38j"))
			playlist.clear()
			return

		song = new_song
		difficulty = new_difficulty.to_lower()
		playlist.pop_front()
		get_tree().reload_current_scene()
		return

	chart = null
	playlist.clear()
	if sound:
		GlobalAudio.get_player("MENU/CANCEL").play()

	song_exited.emit()
	if not exit_scene.is_empty():
		SceneManager.switch_to(load(exit_scene))
		exit_scene = ""
		return
	match mode:
		PlayMode.STORY:
			SceneManager.switch_to(load("uid://dcf86iwg6mn3d"))
		PlayMode.FREEPLAY:
			SceneManager.switch_to(load(MainMenu.freeplay_scene))
		PlayMode.CHARTER:
			SceneManager.switch_to(load('uid://csnprcxwpw805'))
		_:
			SceneManager.switch_to(load("uid://cxk008iuw4n7u"))


func load_chart() -> void:
	if not is_instance_valid(chart):
		chart = Chart.load_song(song, difficulty)
	
	var custom_speed: float = Config.get_value("gameplay", "custom_scroll_speed")
	match Config.get_value("gameplay", "scroll_speed_method"):
		"chart":
			scroll_speed = chart.scroll_speed * custom_speed
		"constant":
			scroll_speed = custom_speed

	Chart.sort_chart_notes(chart)
	Chart.sort_chart_events(chart)

	note_types[&"default"] = load(Note.DEFAULT_PATH)

	# loading external types :3
	for note: NoteData in chart.notes:
		var type: StringName = note.type
		if (note_types.has(type) or
			note_types.has(type.to_snake_case())):
			continue

		# check both full name and snake_case version
		var path: String = "res://scenes/game/notes/%s.tscn" % [type]
		if not ResourceLoader.exists(path):
			type = type.to_snake_case()
			path = "res://scenes/game/notes/%s.tscn" % [type]
			if not ResourceLoader.exists(path):
				continue

		note_types[type] = load(path)


func load_assets() -> void:
	if ResourceLoader.exists("res://assets/songs/%s/meta.tres" % song):
		metadata = load("res://assets/songs/%s/meta.tres" % song)
	if not is_instance_valid(metadata):
		metadata = SongMetadata.new()
		metadata.display_name = song.to_pascal_case()
	
	if ResourceLoader.exists("res://assets/songs/%s/assets.tres" % song):
		assets = load("res://assets/songs/%s/assets.tres" % song)
	if not is_instance_valid(assets):
		assets = SongAssets.new()


func load_from_assets() -> void:
	## Gameplay assets
	player = assets.get_player().instantiate()
	player.is_player = true
	opponent = assets.get_opponent().instantiate()
	spectator = assets.get_spectator().instantiate()
	characters_container.add_child(spectator)
	characters_container.add_child(player)
	characters_container.add_child(opponent)

	stage = assets.get_stage().instantiate()

	# Setup the characters.
	if stage.has_node(^"player"):
		var player_point: CharacterPlacement = stage.get_node(^"player")
		if is_instance_valid(player_point):
			player_point.adjust_character(player)
	if not player.starts_as_player:
		player.scale *= Vector2(-1.0, 1.0)
	
	if stage.has_node(^"opponent"):
		var opponent_point: CharacterPlacement = stage.get_node(^"opponent")
		if is_instance_valid(opponent_point):
			opponent_point.adjust_character(opponent)
	if opponent.starts_as_player:
		opponent.scale *= Vector2(-1.0, 1.0)
	
	if stage.has_node(^"spectator"):
		var spectator_point: CharacterPlacement = stage.get_node(^"spectator")
		if is_instance_valid(spectator_point):
			spectator_point.adjust_character(spectator)
	
	stage_container.add_child(stage)

	## HUD Assets
	hud = assets.get_hud().instantiate()
	if "hud_skin" in hud:
		hud.hud_skin = assets.get_hud_skin()
	hud_layer.add_child(hud)
	
	if "player_field" in hud:
		player_field = hud.player_field
	if "opponent_field" in hud:
		opponent_field = hud.opponent_field

	# Set the NoteField characters.
	if is_instance_valid(player_field):
		player_field.target_character = player
		if is_instance_valid(assets.player_note_skin):
			player_field.skin = assets.player_note_skin
		
		player_field.reload_skin()
	if is_instance_valid(opponent_field):
		opponent_field.target_character = opponent
		if is_instance_valid(assets.opponent_note_skin):
			opponent_field.skin = assets.opponent_note_skin
		
		opponent_field.reload_skin()

	if is_instance_valid(assets.get_hud_skin().pause_menu):
		pause_menu = assets.get_hud_skin().pause_menu
	else:
		pause_menu = load("uid://d3n853hu8o3ik")

	for key: StringName in assets.note_types.keys():
		var scene: PackedScene = assets.note_types.get(key)
		if is_instance_valid(scene):
			note_types[key] = scene

	# we"re done using assets so not point keeping
	# the references around
	assets = null


func setup_hud() -> void:
	if is_instance_valid(player_field):
		player_field.note_types = note_types
		player_field.scroll_speed = scroll_speed
		player_field.append_chart(chart)
		player_field.note_miss.connect(_on_note_miss)
		player_field.note_hit.connect(_on_note_hit)
	if is_instance_valid(opponent_field):
		opponent_field.note_types = note_types
		opponent_field.scroll_speed = scroll_speed
		opponent_field.append_chart(chart)

	hud_setup.emit()


func reset_conductor() -> void:
	conductor.reset()
	conductor.beat_hit.connect(_on_beat_hit)
	conductor.get_bpm_changes(chart.events)
	conductor.calculate_beat()
	conductor.raw_time = -5.0 * conductor.beat_delta


func load_events() -> void:
	if not chart.events.is_empty():
		# Note: this means all custom events just act as normal scripts
		# which should be fine for 99.9% of use cases.
		# it also means you have to manually check for event names
		# but it"s fine :p
		var exceptions: Array[StringName] = []
		for event: EventData in chart.events:
			var event_name: StringName = event.name.to_lower()
			if exceptions.has(event_name):
				continue
			exceptions.push_back(event_name)

			var path: String = "res://scenes/game/events/%s.tscn" % [event_name]
			if not ResourceLoader.exists(path):
				continue

			var scene: PackedScene = load(path)
			var node: Node = scene.instantiate()
			scripts.add_child(node)

		for event: EventData in chart.events:
			event_prepare.emit(event)

		# we do int(time * 1000.0) because if it"s less than 1 ms
		# after the start of a song (i"ve seen this in base game charts before)
		# then we should still call it lmfao (like camera pans)
		while (not chart.events.is_empty()) and events_index < chart.events.size() \
				and int(chart.events[events_index].time * 1000.0) <= 0.0:
			event_hit.emit(chart.events[events_index])
			events_index += 1


func skip_to(seconds: float) -> void:
	if not is_instance_valid(conductor.target_audio):
		conductor.raw_time = seconds
	else:
		conductor.target_audio.seek(seconds)
		conductor.sync_to_target(0.0)
	conductor.calculate_beat()

	if is_instance_valid(opponent_field):
		opponent_field.try_spawning(true)
		opponent_field.clear_notes()

	if is_instance_valid(player_field):
		player_field.try_spawning(true)
		player_field.clear_notes()


enum PlayMode {
	FREEPLAY = 0,
	STORY = 1,
	CHARTER = 2,
	OTHER = 3
}
