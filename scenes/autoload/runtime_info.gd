extends CanvasLayer


@onready var label: Label = $label
@onready var version: String = ProjectSettings.get_setting('application/config/version', 'Unknown')
@onready var timer: Timer = %timer

var video_memory_peak: float = 0.0
var texture_memory_peak: float = 0.0
var static_memory_peak: float = 0.0
var tween: Tween
var debug_info: bool = OS.is_debug_build()

var times: Array[float] = []


func _ready() -> void:
	visible = Config.get_value('performance', 'performance_info_visible')
	Config.value_changed.connect(_on_value_changed)

	_update_timer()


func _process(delta: float) -> void:
	times.push_back(delta)


func display() -> void:
	if not visible:
		return

	var video_memory_current: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	if video_memory_current > video_memory_peak:
		video_memory_peak = video_memory_current

	var texture_memory_current: float = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	if texture_memory_current > texture_memory_peak:
		texture_memory_peak = texture_memory_current

	var static_memory_current: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	if static_memory_current > static_memory_peak:
		static_memory_peak = static_memory_current

	var scene_name: StringName = &'N/A'
	var current_scene: Node = get_tree().current_scene

	if is_instance_valid(current_scene):
		scene_name = current_scene.name.to_pascal_case()

	var avg: float = 0.0
	for time: float in times:
		avg += time / float(times.size())
	times.clear()

	label.size = Vector2.ZERO
	var text_output: String = \
			'%d FPS (%.2fms)\n%s / %s <GPU>\n%s / %s <TEX>\nFunkin\' Godot v%s' % [
		Performance.get_monitor(Performance.TIME_FPS),
		avg * 1000.0,
		String.humanize_size(floori(video_memory_current)),
		String.humanize_size(floori(video_memory_peak)),
		String.humanize_size(floori(texture_memory_current)),
		String.humanize_size(floori(texture_memory_peak)),
		version,
	]

	if debug_info:
		text_output += '\n\n[Debug]\nScene: %s\n%s / %s <CPU>\n%d Nodes (%d Orphaned)\n\n[Conductor]\n%.2fms AudioServer Offset (raw)\n%.2fms Offset (%.2fms manual)\n%.3fs Time\n%.2f Beat, %.2f Step, %.2f Measure\n%.2f BPM\n\n[Rendering]\n%d Draw Calls (%d Drawn Objects)\nAPI: %s' % [
			scene_name,
			String.humanize_size(floori(static_memory_current)),
			String.humanize_size(floori(static_memory_peak)),
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			-AudioServer.get_output_latency() * 1000.0,
			Conductor.offset * 1000.0,
			Conductor.manual_offset * 1000.0,
			Conductor.time, Conductor.beat, Conductor.step, Conductor.measure,
			Conductor.tempo,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Global.get_rendering_api()
		]

	label.text = text_output


func _input(event: InputEvent) -> void:
	if (not event.is_pressed()) or event.is_echo():
		return
	if event.is_action(&'toggle_debug'):
		Config.set_value('performance', 'performance_info_visible', not visible)
	if event.is_action(&'toggle_extra_info'):
		debug_info = not debug_info
		_update_timer()
		display()


func _on_value_changed(section: String, key: String, value: Variant) -> void:
	if section != 'performance':
		return
	if key != 'performance_info_visible':
		return
	if value == null:
		return
	visible = bool(value)


func _update_timer() -> void:
	timer.wait_time = 0.2 if debug_info else 1.0
