@tool
class_name NoteSplash extends AnimatedSprite


@export var colors: Array[Color] = [
	Color('c14b99'),
	Color('00ffff'),
	Color('12fa04'),
	Color('f9393f'),
]

@export var use_default_shader: bool = true
@export var use_skin: bool = true

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
	
	if is_instance_valid(sprite_frames):
		var number: int = randi_range(1, sprite_frames.get_animation_names().size())
		if sprite_frames.has_animation(&"splash %d" % [number,]):
			play(&"splash %d" % [number,])
		else:
			var direction: StringName = note.directions[note.lane]
			var count: int = 0
			for anim: StringName in sprite_frames.get_animation_names():
				if anim.begins_with("%s splash " % [direction,]):
					count += 1
			
			if count > 0:
				number = randi_range(1, count)
				play(&"%s splash %d" % [direction, number,])

	if not use_default_shader:
		return

	if is_instance_valid(note):
		material = material as ShaderMaterial
		material.set_shader_parameter(&"base_color", colors[note.lane])
