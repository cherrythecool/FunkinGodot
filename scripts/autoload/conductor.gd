extends Node


var time: float = 0.0
var rate: float = 1.0
var active: bool = true

var raw_time: float = 0.0
const MAX_DESYNC: float = 25.0 / 1000.0

var tempo: float = 0.0
var tempo_changes: Array[BPMChange] = []

var beat: float = 0.0

## TODO: Time signatures
var step: float = 0.0:
	get:
		return beat * 4.0

var measure: float = 0.0:
	get:
		return beat / 4.0

var beat_delta: float = 0.0:
	get:
		return 60.0 / tempo

var step_delta: float = 0.0:
	get:
		return beat_delta / 4.0

var measure_delta: float = 0.0:
	get:
		return beat_delta * 4.0

var target_audio: AudioStreamPlayer = null
var target_length: float:
	get:
		if is_instance_valid(target_audio) and is_instance_valid(target_audio.stream):
			return target_audio.stream.get_length()

		return -1.0

var audio_offset: float:
	get:
		return -AudioServer.get_output_latency()

var manual_offset: float = 0.0
var offset: float = audio_offset - manual_offset

var last_mix: float = 0.0
var resync_latency: bool = false

signal step_hit(step: int)
signal beat_hit(beat: int)
signal measure_hit(measure: int)


func _ready() -> void:
	Config.value_changed.connect(_on_config_value_changed)
	_on_config_value_changed('gameplay', 'manual_offset',
			Config.get_value('gameplay', 'manual_offset'))
	_on_config_value_changed('sound', 'recalculate_output_latency',
			Config.get_value('sound', 'recalculate_output_latency'))


func _process(delta: float) -> void:
	if not active:
		return

	var mix_delta: float = AudioServer.get_time_since_last_mix()
	if resync_latency:
		if mix_delta < last_mix:
			reset_offset()
		last_mix = mix_delta

	var last_step: int = floori(step)
	var last_beat: int = floori(beat)
	var last_measure: int = floori(measure)

	if is_instance_valid(target_audio):
		sync_to_target(delta)
	else:
		raw_time += delta * rate

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
	var mix_delta: float = AudioServer.get_time_since_last_mix()
	var audio_time: float = target_audio.get_playback_position() + mix_delta
	var desync: float = absf(raw_time - audio_time)
	if desync >= MAX_DESYNC:
		raw_time = audio_time
	else:
		raw_time += delta * target_audio.pitch_scale


func calculate_beat() -> void:
	time = raw_time + offset

	if not tempo_changes.is_empty():
		beat = 0.0

		var last_time: float = 0.0
		var last_change: BPMChange = null
		for change: BPMChange in tempo_changes:
			if maxf(time, 0.0) < change.time:
				break

			tempo = change.data[0]
			beat += (change.time - last_time) / beat_delta
			last_change = change
			last_time = change.time

		beat += (time - last_time) / beat_delta
	else:
		beat = time / beat_delta


func reset() -> void:
	reset_offset()
	target_audio = null
	raw_time = 0.0
	tempo_changes.clear()
	calculate_beat()


func reset_offset() -> void:
	offset = audio_offset - manual_offset


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
	if section == 'sound' and key == 'recalculate_output_latency':
		resync_latency = value
