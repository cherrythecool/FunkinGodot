extends Control


@export var parent: Node2D

@onready var song_label: Label = $song_label
@onready var difficulty_label: Label = $difficulty_label
@onready var score_panel: Panel = %score_panel
@onready var reset_panel: Panel = %reset_panel

var song: StringName
var difficulty: StringName
var difficulty_count: int = 0
var score_data: Dictionary
var song_index: int
var song_node: FreeplaySongNode


func _ready() -> void:
	if not is_instance_valid(parent):
		parent = get_tree().current_scene

	parent.song_changed.connect(_on_song_changed)
	parent.difficulty_changed.connect(_on_difficulty_changed)


func _process(_delta: float) -> void:
	score_panel.position.y = size.y + 24.0
	reset_panel.position.y = score_panel.position.y + score_panel.size.y + 16.0


func _on_song_changed(index: int) -> void:
	song_index = index
	song_node = parent.song_nodes[song_index]
	song_label.text = parent.song_nodes[song_index].text


func _on_difficulty_changed(new_difficulty: StringName) -> void:
	var difficulty_map: DifficultyMap = song_node.song.difficulty_remap
	difficulty = new_difficulty

	if (
		is_instance_valid(difficulty_map)
		and difficulty_map.mapping.has(difficulty)
	):
		song = difficulty_map.mapping.get(difficulty)
	else:
		song = song_node.song.song_name

	reset_panel.song = song
	reset_panel.difficulty = difficulty

	score_data = Scores.get_score(song, difficulty)
	score_panel.refresh(score_data)

	if difficulty_count > 1:
		difficulty_label.text = '< %s >' % tr(difficulty.to_lower()).to_upper()
		difficulty_label.visible = true
		size.y = 45.0
	else:
		difficulty_label.visible = false
		size.y = 24.0
