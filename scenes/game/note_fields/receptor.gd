class_name Receptor extends Node2D


@export var direction: StringName = &'left'
@export var lane: int = 0
@export var takes_input: bool = false:
	set(value):
		takes_input = value
		if (not takes_input) and not Config.get_value('interface', 'cpu_strums_press'):
			play_confirm = false

@onready var sprite: AnimatedSprite2D = $sprite
@onready var automatically_play_static: bool = false:
	set(value):
		if automatically_play_static != value:
			if value:
				sprite.animation_finished.connect(_on_animation_finished)
			elif sprite.animation_finished.is_connected(_on_animation_finished):
				sprite.animation_finished.disconnect(_on_animation_finished)

			automatically_play_static = value

var play_confirm: bool = true
var pressed: bool = false
var last_anim: StringName = &''


func _ready() -> void:
	if automatically_play_static:
		sprite.animation_finished.connect(_on_animation_finished)


func play_anim(anim: StringName, force: bool = false) -> void:
	last_anim = anim
	sprite.play(&'%s %s' % [direction, anim])

	if force:
		sprite.frame = 0


func hit_note(_note: Note) -> void:
	if takes_input or play_confirm:
		play_anim(&'confirm', true)


func _on_animation_finished() -> void:
	if sprite.animation.ends_with(&'static'):
		return

	play_anim(&'static')
