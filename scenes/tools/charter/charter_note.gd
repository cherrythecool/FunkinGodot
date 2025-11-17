extends AnimatedSprite2D

@onready var rect: Control = %rect
var data: NoteData = null
var lane: int = 0:
	set(value):
		lane = value
		animation = &'%s note' % [Note.directions[lane % Note.directions.size()]]
		play()

var length: float = 0:
	set(value):
		length = value
		if length < 0:
			length = 0
		$sustain.visible = value != 0
		$sustain.size.y = (123*1.5) *Conductor.instance.get_time_in_step(length*1000)

var is_event:bool = false:
	set(value):
		is_event = value
		if is_event:
			self.self_modulate.a = 0
			get_node("%event").visible = true
		else:
			self.self_modulate.a = 1
			get_node("%event").visible = false
var event_data: EventData = null

func setup(note_data: NoteData) -> void:
	self.data = note_data
	lane = absi(data.direction)
	self.length = note_data.length
	
	var sustain_texture: AtlasTexture = sprite_frames.get_frame_texture('%s sustain' % [
		Note.directions[lane % Note.directions.size()]
	], 0).duplicate()
	sustain_texture.region.position.y += 1
	sustain_texture.region.size.y -= 2

	$sustain.texture = sustain_texture

	var tail_texture: AtlasTexture = sprite_frames.get_frame_texture('%s sustain end' % [
		Note.directions[lane % Note.directions.size()]
	], 0).duplicate()
	tail_texture.region.position.y += 1
	tail_texture.region.size.y -= 1

	$sustain/tail.texture = tail_texture
	$sustain/tail.size.y = $sustain/tail.texture.get_height()

func setup_event(event_data: EventData) -> void:
	is_event = true
	self.event_data = event_data
	var texture_path: String = 'res://assets/tools/charter/events/%s.png' % [event_data.name.to_lower()]
	if ResourceLoader.exists(texture_path):
		get_node("%event").texture = load(texture_path)
	else:
		get_node("%event").texture = load( 'res://assets/tools/charter/events/default.png')
