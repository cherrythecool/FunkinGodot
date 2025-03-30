class_name FreeplayMenu extends Node2D


static var index: int = 0
static var difficulty_index: int = 0

@export var list: Array[FreeplaySong] = []

@onready var background: Sprite2D = %background
var target_background_color: Color = Color.WHITE
@onready var songs = %songs
var song_nodes: Array[FreeplaySongNode] = []

@onready var tracks: Tracks = %tracks
@onready var track_timer: Timer = %track_timer
@onready var _info_panel: Panel = %info_panel

var list_song: FreeplaySong:
	get: return list[index]

var current_song: String:
	get:
		if not is_instance_valid(list_song):
			return ''

		return _get_song_name(list_song, difficulty)

var difficulties: PackedStringArray:
	get: return list_song.song_difficulties

var difficulty: String:
	get: return difficulties[difficulty_index]

var active: bool = true
var previous_song: String

signal song_changed(index: int)
signal difficulty_changed(difficulty: StringName)


func _ready() -> void:
	randomize()
	assert(not list.is_empty(), 'You need a list to have freeplay work correctly.')

	for i: int in list.size():
		_load_song(i)

	if song_nodes.is_empty():
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		SceneManager.switch_to('scenes/menus/main_menu.tscn')
		printerr('Freeplay has no songs, returning.')
		return

	Conductor.reset()
	tracks.finished.connect(_on_finished)

	change_selection()
	target_background_color = song_nodes[index].song.icon.color
	background.modulate = target_background_color


func _process(delta: float) -> void:
	background.modulate = background.modulate.lerp(target_background_color, delta * 5.0)


func _input(event: InputEvent) -> void:
	if not active:
		return
	if not event.is_pressed():
		return

	if event.is_action('ui_cancel'):
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		SceneManager.switch_to('scenes/menus/main_menu.tscn')
	if event.is_action('ui_accept'):
		active = false
		call_deferred('select_song')
	if event.is_action(&'freeplay_open_characters'):
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		SceneManager.switch_to('uid://62vvv8x8t7nm')

	if event.is_action('ui_up') or event.is_action('ui_down'):
		change_selection(Input.get_axis('ui_up', 'ui_down'))
	if event.is_action('ui_left') or event.is_action('ui_right'):
		change_difficulty(Input.get_axis('ui_left', 'ui_right'))

	if event.is_action('freeplay_random'):
		change_selection(randi_range(-song_nodes.size() + 1, song_nodes.size() - 1))


func _get_song_name(song: FreeplaySong, diff: String) -> String:
	if not is_instance_valid(song.difficulty_remap):
		return song.song_name.to_lower()

	return song.difficulty_remap.mapping.get(diff, song.song_name).to_lower()


func change_selection(amount: int = 0) -> void:
	index = wrapi(index + amount, 0, song_nodes.size())
	song_changed.emit(index)
	change_difficulty()
	previous_song = current_song

	track_timer.start(0.0)

	if amount != 0:
		GlobalAudio.get_player('MENU/SCROLL').play()
	for i: int in song_nodes.size():
		var node := song_nodes[i]
		node.target_y = i - index
		node.modulate.a = 1.0 if node.target_y == 0 else 0.6

	target_background_color = song_nodes[index].song.icon.color


func change_difficulty(amount: int = 0) -> void:
	difficulty_index = wrapi(difficulty_index + amount, 0, difficulties.size())
	_info_panel.difficulty_count = difficulties.size()
	if difficulties.is_empty():
		difficulty_changed.emit(&'N/A')
	else:
		difficulty_changed.emit(difficulties[difficulty_index])

	# there has been a change and the song should switch
	if current_song != previous_song:
		track_timer.start(0.0)
		previous_song = current_song


func select_song() -> void:
	if difficulties.is_empty():
		active = true
		return

	Game.chart = Chart.load_song(current_song, difficulty)
	if not is_instance_valid(Game.chart):
		var json_path := 'res://assets/songs/%s/charts/%s.json' % [current_song, difficulty.to_lower()]
		active = true
		printerr('Song at path %s doesn\'t exist!' % json_path)
		return

	Game.song = current_song
	Game.difficulty = difficulty.to_lower()
	Game.mode = Game.PlayMode.FREEPLAY
	Game.playlist.clear()
	SceneManager.switch_to('scenes/game/game.tscn')


func _load_song(i: int) -> void:
	var song := list[i]
	if song.song_difficulties.size() < 1:
		printerr('Song is missing any difficulties!')
		return

	var song_name := _get_song_name(song, song.song_difficulties[0])
	var meta_path: String = 'res://assets/songs/%s/meta.tres' % song_name
	var meta_exists := ResourceLoader.exists(meta_path)

	if not meta_exists:
		var node := FreeplaySongNode.new()
		node.position = Vector2.ZERO
		node.song = song
		node.text = song.song_name
		node.target_y = i
		node.modulate = Color.SALMON
		song_nodes.push_back(node)
		songs.add_child(node)

		var lock := Sprite2D.new()
		lock.texture = load('res://resources/images/menus/story_menu/interface/lock.png')
		lock.position = Vector2(node.size.x + 75.0, 35.0)
		lock.modulate = Color.WHITE / node.modulate
		node.add_child(lock)
		return

	song.song_meta = load(meta_path)

	var node := FreeplaySongNode.new()
	node.position = Vector2.ZERO
	node.song = song
	node.text = song.song_meta.display_name
	node.target_y = i
	song_nodes.push_back(node)
	songs.add_child(node)

	if not is_instance_valid(song.icon):
		song.icon = Icon.new()

	var icon := Icon.create_sprite(song.icon)
	# 37.5 = 150.0 * 0.25
	icon.position = Vector2(node.size.x + 75.0, 37.5)
	node.add_child(icon)


func _load_tracks() -> void:
	if not Tracks.tracks_exist(current_song, 'res://assets/songs'):
		return

	GlobalAudio.music.stop()
	Conductor.reset()
	Conductor.target_audio = tracks.player
	tracks.load_tracks(current_song, 'res://assets/songs')
	tracks.play()


func _on_finished() -> void:
	Conductor.reset()
	tracks.play()
