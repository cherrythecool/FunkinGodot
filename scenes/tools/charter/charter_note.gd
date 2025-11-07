extends AnimatedSprite2D

@onready var rect: Control = %rect
var data: NoteData = null
var lane: int = 0

var length: float = 0:
	set(value):
		length = value
		$sustain.visible = value != 0
		$sustain.size.y = (123*1.5) *Conductor.get_time_in_step(length*1000)
			

func setup(note_data:NoteData) -> void:
	self.data = note_data
	lane = absi(data.direction) % Note.directions.size()
	self.length = note_data.length

	animation = &'%s note' % [Note.directions[lane]]
	play()
	
	var sustain_texture: AtlasTexture = sprite_frames.get_frame_texture('%s sustain' % [
		Note.directions[lane]
	], 0).duplicate()
	sustain_texture.region.position.y += 1
	sustain_texture.region.size.y -= 2

	$sustain.texture = sustain_texture

	var tail_texture: AtlasTexture = sprite_frames.get_frame_texture('%s sustain end' % [
		Note.directions[lane]
	], 0).duplicate()
	tail_texture.region.position.y += 1
	tail_texture.region.size.y -= 1

	$sustain/tail.texture = tail_texture
	$sustain/tail.size.y = $sustain/tail.texture.get_height()
