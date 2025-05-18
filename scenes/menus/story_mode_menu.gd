extends Control


@onready var songs: Control = %songs
@onready var songs_label: Label = songs.get_node('songs_label')

@onready var difficulties: Control = %difficulties
@onready var weeks: Control = %weeks
@onready var props: Node2D = %props

@onready var high_score: Label = %high_score
@onready var week_name: Label = %week_name

var active: bool = true


func _ready() -> void:
	var music_player: AudioStreamPlayer = GlobalAudio.music
	if not music_player.playing:
		Conductor.reset()
		music_player.play()
		Conductor.tempo = 102.0
		Conductor.target_audio = music_player
	Conductor.beat_hit.connect(_on_beat_hit)

	change_selection()


func _on_beat_hit(_beat: int) -> void:
	if not active:
		return

	props.beat_hit()


func _process(delta: float) -> void:
	var target_y: float = 86.0 - weeks.get_child(weeks.selected).position.y
	weeks.position.y = lerpf(weeks.position.y, target_y, minf(delta * 6.0, 1.0))


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action('ui_cancel'):
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		SceneManager.switch_to('scenes/menus/main_menu.tscn')
	if event.is_action('ui_accept'):
		active = false
		_load_active_playlist()

		if _load_first_song():
			GlobalAudio.get_player('MENU/CONFIRM').play()
			if is_instance_valid(props.props[2]):
				props.props[2].play_anim('confirm', true)

			SceneManager.switch_to('scenes/game/game.tscn')
		else:
			active = true
	if event.is_action('ui_up') or event.is_action('ui_down'):
		var movement: int = int(Input.get_axis('ui_up', 'ui_down'))
		change_selection(movement)
	if event.is_action('ui_left') or event.is_action('ui_right'):
		var movement: int = int(Input.get_axis('ui_left', 'ui_right'))
		difficulties.change_selection(movement)


func _load_active_playlist() -> void:
	var selected_week: StoryWeekNode = weeks.get_child(weeks.selected)
	Game.playlist = []
	if selected_week.songs.size() == 1:
		return

	var difficulty: String = difficulties.difficulties[difficulties.selected]
	for i: int in range(1, selected_week.songs.size()):
		var entry: GamePlaylistEntry = GamePlaylistEntry.new()
		entry.name = selected_week.get_song_name(i, difficulty)
		entry.difficulty = difficulty
		Game.playlist.push_back(entry)


func _load_first_song() -> bool:
	var selected_week: StoryWeekNode = weeks.get_child(weeks.selected)
	var difficulty: String = difficulties.difficulties[difficulties.selected]
	var song_name: String = selected_week.get_song_name(0, difficulty)
	Game.chart = Chart.load_song(song_name, difficulty)

	if not is_instance_valid(Game.chart):
		var json_path: String = (
			'res://assets/songs/%s/charts/%s.json'
			% [song_name, difficulty.to_lower()]
		)
		printerr('Song at path %s doesn\'t exist!' % json_path)
		GlobalAudio.get_player('MENU/CANCEL').play()
		return false

	Game.song = song_name
	Game.difficulty = difficulty.to_lower()
	Game.mode = Game.PlayMode.STORY
	return true


func change_selection(amount: int = 0) -> void:
	weeks.selected = wrapi(weeks.selected + amount, 0, weeks.get_child_count())

	var selected_week: StoryWeekNode = weeks.get_child(weeks.selected)
	props.update_props(selected_week.props)
	week_name.text = selected_week.display_name
	difficulties.difficulties = selected_week.difficulties
	difficulties.change_selection()

	var song_paths: PackedStringArray = selected_week.songs
	var song_names: PackedStringArray = []

	for path: String in song_paths:
		if ResourceLoader.exists('res://assets/songs/%s/meta.tres' % path):
			var meta: SongMetadata = load('res://assets/songs/%s/meta.tres' % path)
			song_names.push_back(meta.display_name)
		else:
			song_names.push_back(path)

	songs_label.text = '\n'.join(song_names)

	if amount != 0:
		GlobalAudio.get_player('MENU/SCROLL').play()
