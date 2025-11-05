@tool
extends AnimatedSprite

var data: NoteData = null

var lane: int = 0

func setup(note_data:NoteData) -> void:
	self.data = note_data
	lane = absi(data.direction) % Note.directions.size()

	animation = &'%s note' % [Note.directions[lane]]
	play()
