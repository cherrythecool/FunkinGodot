extends Panel


@onready var info_panel: Panel = %info_panel

var active: bool = false
var song: StringName = &''
var difficulty: StringName = &''


func _process(_delta: float) -> void:
	visible = active


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action(&'freeplay_random'): # same keybind moment
		return
	if event.is_action(&'freeplay_reset_score'):
		active = true
	if not active:
		return

	var axis: int = roundi(Input.get_axis(&'freeplay_no', &'freeplay_yes'))
	if axis:
		active = false
		if axis > 0:
			Scores.reset_score(song, difficulty)
			info_panel._on_difficulty_changed(difficulty)
