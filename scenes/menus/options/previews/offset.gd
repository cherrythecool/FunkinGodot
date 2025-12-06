extends Node2D


@onready var NOTE: PackedScene = load("res://scenes/game/notes/note.tscn")
@onready var notes: NoteField = $notes

var lane: int = 0


func _ready() -> void:
	Config.value_changed.connect(_on_value_changed)
	Conductor.instance.beat_hit.connect(_on_beat_hit)
	notes.scroll_speed = Config.get_value("gameplay", "custom_scroll_speed")


func _process(_delta: float) -> void:
	# clean up notes when song restarts
	for note: Note in notes.notes:
		if note.data.time - Conductor.instance.time >= 4.0:
			notes.remove_note(note)


func _on_beat_hit(beat: int) -> void:
	var data: NoteData = NoteData.new()
	data.time = Conductor.instance.raw_time + (Conductor.instance.beat_delta * 4.0)
	data.beat = float(beat + 4.0)
	data.direction = lane
	data.length = 0.0
	data.type = &"default"
	notes.spawn_note(data)
	lane = wrapi(lane + 1, 0, 4)


func _on_value_changed(section: String, key: String, value: Variant) -> void:
	if section == "gameplay" and key == "custom_scroll_speed":
		notes.scroll_speed = value
