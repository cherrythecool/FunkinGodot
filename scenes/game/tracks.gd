## A class that handles the audio tracks for a given
## in-game song, managing their timing and sync,
## as well as generally loading them.
class_name Tracks extends Node


## Name is self explanatory but its measured in seconds.
const MINIMUM_DESYNC_ALLOWED: float = 0.010

@export var stop_on_finish: bool = false

@onready var player: AudioStreamPlayer = $player
var playing: bool:
	get:
		return player.is_playing()

@export var looping: bool = false:
	set(value):
		looping = value
		set_tracks_looping(looping)

var last_playback_position: float = 0.0

signal finished


## Sets the looping value of all tracks in use.
func set_tracks_looping(looping: bool) -> void:
	if not (is_instance_valid(player) and is_instance_valid(player.stream)):
		return
	var tracks: Array[AudioStream] = []
	if player.stream is AudioStreamSynchronized:
		for i in player.stream.stream_count:
			tracks.push_back(player.stream.get_sync_stream(i))
	else:
		tracks.push_back(player.stream)

	for track in tracks:
		if track is AudioStreamMP3 or track is AudioStreamOggVorbis:
			track.loop = looping
		elif track is AudioStreamWAV:
			track.loop_mode = AudioStreamWAV.LOOP_FORWARD \
					if looping else AudioStreamWAV.LOOP_DISABLED


## Tries to find tracks of the specified song and path,
## returns true if they exist and false if they don't.
static func tracks_exist(song: StringName, path: String) -> bool:
	return is_instance_valid(find_tracks(song, path))


## Finds and loads the tracks for the given song and path.
##
## Will try to first load a tracks.tres file if found, and if not
## will generate an AudioStreamSynchronized if a tracks folder
## can be found. (Loading all resources in the folder)
static func find_tracks(song: StringName, path: String) -> AudioStream:
	var song_folder: String = '%s/%s' % [path, song]
	if ResourceLoader.exists('%s/tracks.tres' % [song_folder]):
		return load('%s/tracks.tres' % [song_folder])

	var files := ResourceLoader.list_directory('%s/tracks' % [song_folder])
	if files.is_empty():
		return null

	var tracks := AudioStreamSynchronized.new()
	for file in files:
		tracks.stream_count += 1
		tracks.set_sync_stream(tracks.stream_count - 1, load('%s/%s/tracks/%s' % \
				[path, song, file,]))

	return tracks


## Loads the audio tracks from the song [param song]
## and places them into this Node as separate [AudioStreamPlayerEX]s.
func load_tracks(song: StringName, song_path: String = '') -> void:
	if song_path.is_empty():
		song_path = 'res://assets/songs'

	# Shouldn't be an issue but just to be sure.
	if song_path.ends_with('/'):
		song_path = song_path.left(song_path.length() - 1)

	var tracks: AudioStream = find_tracks(song, song_path)
	if not tracks:
		printerr('ERROR: Couldn\'t find a tracks.tres (or tracks folder) for song "%s" at song_path "%s"' \
				% [song, song_path])
		return

	var index: int = 1
	player.stream = tracks
	player.bus = &'Music'
	looping = looping

	if not player.finished.is_connected(_on_finished):
		player.finished.connect(_on_finished)


## Plays all tracks from position [param from_position].
func play(from_position: float = 0.0) -> void:
	player.play(from_position)


## Stops all tracks at once.
func stop() -> void:
	player.stop()


## Checks the sync of all tracks and resyncs them if they
## are out of sync with each other.
func check_sync(force: bool = false) -> void:
	if not is_instance_valid(player.stream):
		return
	# With the newer target audio system it's
	# no longer required to resync manually like this.
	if Conductor.target_audio == player:
		return

	var last_time: float = Conductor.time
	var track_index: int = 0

	var target_time := player.get_playback_position()
	var desync: float = absf(target_time - Conductor.time + Conductor.offset)
	var any_desynced: bool = force or desync >= 0.02

	if not any_desynced:
		return

	#print('Resynced with %.3fms of desync!%s' % [desync * 1000.0,
	#		' (forced)' if force else ''])
	Conductor.time = get_playback_position()
	Conductor.beat += (Conductor.time - last_time) * Conductor.beat_delta


## Gets the playback position (factoring in offset) from the track specified.
func get_playback_position() -> float:
	if not is_instance_valid(player.stream) or not player.is_playing():
		return Conductor.time

	return player.get_playback_position() + AudioServer.get_time_since_last_mix()\
			 + Conductor.offset


## Gets the length from the currently available stream or 0 otherwise.
func get_length() -> float:
	if not is_instance_valid(player.stream):
		return 0.0

	return player.stream.get_length()


## Sets the playback position of all tracks and Conductor.time to the position
## specified.
func set_playback_position(position: float) -> void:
	if not is_instance_valid(player.stream) or not player.is_playing():
		return
	if position < 0.0:
		position = 0.0

	player.seek(position)

	var last_time: float = Conductor.time
	Conductor.time = position + Conductor.offset
	Conductor.beat += (Conductor.time - last_time) * Conductor.beat_delta


func _physics_process(delta: float) -> void:
	if playing:
		check_sync()
	elif is_instance_valid(Game.instance) and Game.instance.song_started:
		_on_finished()

	last_playback_position = player.get_playback_position()


func _on_finished() -> void:
	player.stop()
	finished.emit()
	if stop_on_finish:
		process_mode = Node.PROCESS_MODE_DISABLED
