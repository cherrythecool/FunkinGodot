class_name Receptor extends Node2D


static var input_zone: float = 0.18


@export var direction: StringName = &'left'
@export var lane: int = 0
@export var takes_input: bool = false:
	set(value):
		takes_input = value
		if (not takes_input) and not Config.get_value('interface', 'cpu_strums_press'):
			play_confirm = false

@onready var sprite: AnimatedSprite2D = $sprite
@onready var _automatically_play_static: bool = false:
	set(value):
		if _automatically_play_static != value:
			if value:
				sprite.animation_finished.connect(_on_animation_finished)
			elif sprite.animation_finished.is_connected(_on_animation_finished):
				sprite.animation_finished.disconnect(_on_animation_finished)

			_automatically_play_static = value
var play_confirm: bool = true
var _pressed: bool = false
var _last_anim: StringName = &''
@onready var _notes: Node2D = %notes

signal on_hit_note(note: Note)
signal on_miss_note(note: Note)


func _unhandled_input(event: InputEvent) -> void:
	if not takes_input:
		return
	if event.is_echo():
		return

	if not event.is_action(&'input_%s' % direction):
		return

	var pressed: bool = event.is_pressed()
	if pressed:
		_pressed = true
		play_anim(&'press')
		_automatically_play_static = false

		for note: Note in _notes.get_children():
			var before_zone: bool = Conductor.time < note.data.time - input_zone
			if before_zone:
				break
			if note._hit:
				continue
			if note.lane != lane:
				continue

			var after_zone: bool = Conductor.time > note.data.time + input_zone
			if not (before_zone or after_zone):
				hit_note(note)
				break
			break
	else:
		_pressed = false
		play_anim(&'static')

		for note: Note in _notes.get_children():
			var before_zone: bool = Conductor.time < note.data.time - input_zone
			if before_zone:
				break
			if not note._hit:
				continue
			if note.lane != lane:
				continue

			var lee_way: float = maxf(Conductor.beat_delta / 4.0, 0.1)
			# give a bit of lee-way
			if note.length < lee_way:
				# we do this because the animations get funky sometimes lol
				_automatically_play_static = true
				continue

			on_miss_note.emit(note)


func hit_note(note: Note) -> void:
	if takes_input or play_confirm:
		play_anim(&'confirm', true)
	on_hit_note.emit(note)


func _ready() -> void:
	if _automatically_play_static:
		sprite.animation_finished.connect(_on_animation_finished)


func play_anim(anim: StringName, force: bool = false) -> void:
	_last_anim = anim
	sprite.play(&'%s %s' % [direction, anim])

	if force:
		sprite.frame = 0


func _on_animation_finished() -> void:
	if sprite.animation.ends_with(&'static'):
		return

	play_anim(&'static')
