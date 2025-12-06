extends Label


@onready var timer: Timer = $timer

var state: SongLabelState = SongLabelState.WAITING_DOWN


func _tick() -> void:
	var line_count: int = text.strip_edges().count('\n')
	if line_count <= max_lines_visible:
		return

	match state:
		SongLabelState.WAITING_DOWN:
			state = SongLabelState.DOWN
		SongLabelState.WAITING_UP:
			state = SongLabelState.UP
		SongLabelState.DOWN:
			if lines_skipped < line_count - max_lines_visible + 1:
				lines_skipped += 1
			else:
				state = SongLabelState.WAITING_UP
		SongLabelState.UP:
			if lines_skipped > 0:
				lines_skipped -= 1
			if lines_skipped == 0:
				state = SongLabelState.WAITING_DOWN


enum SongLabelState {
	DOWN = 0,
	WAITING_DOWN,
	UP,
	WAITING_UP,
}
