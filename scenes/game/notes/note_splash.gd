@tool
class_name NoteSplash extends AnimatedSprite


@export var colors: Array[Color] = [
	Color('c14b99'),
	Color('00ffff'),
	Color('12fa04'),
	Color('f9393f'),
]

@export var use_default_shader: bool = true

var note: Note


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	animation_finished.connect(queue_free)
	if is_instance_valid(note):
		modulate.a = note.field.note_splash_alpha

	if modulate.a <= 0.0:
		queue_free()
		return

	speed_scale = randf_range(0.9, 1.1)
	play(&"splash %d" % [randi_range(1, sprite_frames.get_animation_names().size())])

	if not use_default_shader:
		return

	if is_instance_valid(note):
		material = material as ShaderMaterial
		material.set_shader_parameter(&"base_color", colors[note.lane])
