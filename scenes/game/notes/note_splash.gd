@tool
class_name NoteSplash extends AnimatedSprite


@export var use_skin: bool = true

const colors: Array[Color] = [
	Color('c14b99'), Color('00ffff'), Color('12fa04'), Color('f9393f'),]

var note: Note


func _ready() -> void:
	if not is_instance_valid(note):
		return

	modulate.a = note.field._note_splash_alpha
	if modulate.a <= 0.0:
		queue_free()
		return

	speed_scale = randf_range(0.9, 1.1)
	play('splash %d' % [randi_range(1, sprite_frames.get_animation_names().size())])

	if not use_skin:
		return

	material = material as ShaderMaterial
	material.set_shader_parameter(&'base_color', colors[note.lane])
