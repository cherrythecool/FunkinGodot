extends CanvasLayer


@export var icons: Array[Texture2D] = []

@onready var panel: Panel = $root/panel
@onready var bar: ProgressBar = $root/panel/bar
@onready var volume_label: Label = $root/panel/volume_label
@onready var icon_label: Label = $root/panel/icon_label
@onready var icon_rect: TextureRect = $root/panel/icon

var tween: Tween
var target_bus: StringName = &'Master'
var volume: float = 0.5:
	set(value):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(target_bus),
				linear_to_db(value))

		var buses: Dictionary = Config.get_value('sound', 'buses')
		buses[target_bus] = value * 100.0
		Config.set_value('sound', 'buses', buses)
	get:
		return db_to_linear(AudioServer.get_bus_volume_db(\
				AudioServer.get_bus_index(target_bus)))


func _ready() -> void:
	visible = false
	var buses: Dictionary = Config.get_value('sound', 'buses')

	for bus: String in buses.keys():
		var bus_index: int = AudioServer.get_bus_index(bus)
		if bus_index < 0:
			continue

		AudioServer.set_bus_volume_db(bus_index, \
				linear_to_db(buses.get(bus, 100.0) * 0.01))


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not (event.is_action('volume_down') or event.is_action('volume_up')):
		return

	var direction: int = roundi(Input.get_axis('volume_down', 'volume_up'))
	if direction == 0:
		return

	if is_instance_valid(tween) and tween.is_running():
		tween.kill()

	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, 'size:y', 92, 0.5)
	tween.tween_property(panel, 'size:y', 0, 0.5).set_delay(1.0)
	tween.tween_property(self, 'visible', false, 0.0)
	visible = true

	var modifier: int = roundi(Input.get_axis('alt', 'shift'))
	var bus_index: int = AudioServer.get_bus_index(target_bus)

	match modifier:
		0:
			volume = clampf(volume + 0.05 * direction, 0.0, 1.0)
		-1:
			bus_index = wrapi(bus_index + direction, 0, AudioServer.bus_count)
			target_bus = AudioServer.get_bus_name(bus_index)
		1:
			volume = clampf(volume + 0.01 * direction, 0.0, 1.0)

	bar.value = volume * 100.0
	volume_label.text = '%d%% Volume' % [roundi(volume * 100.0)]
	icon_label.text = target_bus
	icon_rect.texture = icons[bus_index] if bus_index < icons.size() else icons[0]
