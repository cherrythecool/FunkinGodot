extends Node2D


@onready var NOTE: PackedScene = load('res://scenes/game/notes/note.tscn')
@onready var notes: NoteField = $notes

var lane: int = 0



func _ready() -> void:
	Config.value_changed.connect(_on_value_changed)
	Conductor.beat_hit.connect(_on_beat_hit)
	notes._force_no_chart = true
	notes._chart = null
	notes._scroll_speed = Config.get_value('gameplay', 'custom_scroll_speed')


func _process(_delta: float) -> void:
	# clean up notes when song restarts
	for note: Note in notes._notes.get_children():
		if note.data.time - Conductor.time >= 4.0:
			note.queue_free()


func _on_beat_hit(beat: int) -> void:
	var note: Note = NOTE.instantiate()
	note.data = NoteData.new()
	note.data.time = Conductor.raw_time + (Conductor.beat_delta*4.0)
	note.data.beat = float(beat + 4.0)
	note.data.direction = lane
	note.data.length = 0.0
	note.data.type = &'default'
	note.position.x = notes._receptors[0].position.x + 112.0 * lane
	note.position.y = -4000.0
	notes._notes.add_child(note)
	note.lane = lane

	lane = wrapi(lane + 1, 0, 4)


func _on_value_changed(section: String, key: String, value: Variant) -> void:
	if section != 'gameplay':
		return
	if key != 'custom_scroll_speed':
		return
	if value == null:
		return
	notes._scroll_speed = value
