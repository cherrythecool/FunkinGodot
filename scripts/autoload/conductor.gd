class_name Conductor extends Node


static var instance: Conductor = null

static var audio_offset: float:
	get:
		return -AudioServer.get_output_latency()
static var manual_offset: float = 0.0
static var offset: float = audio_offset - manual_offset

var time: float:
	get:
		return raw_time + offset

# We need this internal variable to let you
# properly modify rate in editor export at runtime
var internal_rate: float = 1.0
@export var rate: float = 1.0:
	set(value):
		Engine.time_scale = maxf(value, 0.0)
		if is_instance_valid(target_audio):
			target_audio.pitch_scale = value
		internal_rate = value
		rate_changed.emit(value)
	get:
		if is_instance_valid(target_audio):
			return target_audio.pitch_scale
		
		return internal_rate
@export var active: bool = true

var raw_time: float = 0.0
const MAX_DESYNC: float = 20.0 / 1000.0

@export var tempo: float = 0.0
@export var tempo_changes: Array[BPMChange] = []

var beat: float = 0.0

## TODO: Time signatures
var step: float:
	get:
		return beat * 4.0

var measure: float:
	get:
		return beat / 4.0

var beat_delta: float:
	get:
		return 60.0 / tempo

var sustain_release_delta: float:
	get:
		return beat_delta / 2.0

var step_delta: float:
	get:
		return beat_delta / 4.0

var measure_delta: float:
	get:
		return beat_delta * 4.0

var target_audio: AudioStreamPlayer = null
var target_length: float:
	get:
		if is_instance_valid(target_audio) and is_instance_valid(target_audio.stream):
			return target_audio.stream.get_length()
		return 1.0

signal step_hit(step: int)
signal beat_hit(beat: int)
signal measure_hit(measure: int)
signal rate_changed(rate: float)


func _exit_tree() -> void:
	if instance == self:
		rate = 1.0
		instance = null


func _ready() -> void:
	if not is_instance_valid(instance):
		instance = self
	
	Config.value_changed.connect(_on_config_value_changed)
	_on_config_value_changed('gameplay', 'manual_offset',
			Config.get_value('gameplay', 'manual_offset'))
	SceneManager.scene_changed.connect(_on_scene_changed)


func _process(delta: float) -> void:
	if not active:
		return

	var last_step: int = floori(step)
	var last_beat: int = floori(beat)
	var last_measure: int = floori(measure)

	if is_instance_valid(target_audio):
		sync_to_target(delta)
	else:
		raw_time += delta

	calculate_beat()

	if floori(step) > last_step:
		for step_value: int in range(last_step + 1, floori(step) + 1):
			step_hit.emit(step_value)
	if floori(beat) > last_beat:
		for beat_value: int in range(last_beat + 1, floori(beat) + 1):
			beat_hit.emit(beat_value)
	if floori(measure) > last_measure:
		for measure_value: int in range(last_measure + 1, floori(measure) + 1):
			measure_hit.emit(measure_value)


func sync_to_target(delta: float) -> void:
	var audio_time: float = GameUtils.get_accurate_time(target_audio)
	var desync: float = absf(raw_time - audio_time)
	if audio_time > raw_time or desync >= MAX_DESYNC:
		raw_time = audio_time
	else:
		raw_time += delta


func calculate_beat() -> void:
	time = raw_time + offset
	if tempo_changes.is_empty():
		beat = time / beat_delta
		return

	beat = 0.0
	tempo = tempo_changes[0].data[0]

	var last_time: float = 0.0
	for change: BPMChange in tempo_changes:
		if maxf(time, 0.0) < change.time:
			break

		beat += (change.time - last_time) / beat_delta
		last_time = change.time
		tempo = change.data[0]

	beat += (time - last_time) / beat_delta


func reset() -> void:
	reset_offset()
	target_audio = null
	raw_time = 0.0
	tempo_changes.clear()
	calculate_beat()


static func reset_offset() -> void:
	const SUPPORTED_PLATFORMS: PackedStringArray = [
		"Linux",
		"Web",
	]
	
	if SUPPORTED_PLATFORMS.has(OS.get_name()):
		offset = audio_offset - manual_offset
	else:
		offset = -manual_offset


func get_bpm_changes(events: Array[EventData], clear: bool = true) -> void:
	if clear:
		tempo_changes.clear()

	for event: EventData in events:
		if event is BPMChange:
			tempo_changes.push_back(event as BPMChange)

	tempo_changes.sort_custom(func(a: BPMChange, b: BPMChange) -> bool:
		return a.time < b.time)


func _on_config_value_changed(section: String, key: String, value: Variant) -> void:
	if section == 'gameplay' and key == 'manual_offset':
		manual_offset = value / 1000.0


func _on_scene_changed() -> void:
	reset_offset()
