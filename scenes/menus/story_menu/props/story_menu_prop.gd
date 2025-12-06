extends Node2D
class_name StoryMenuProp


@export var dance_steps: PackedStringArray = ['idle']

@onready var animation_player: AnimationPlayer = %animation_player

var dance_step: int = 0
var last_animation: StringName

signal animation_finished(animation: StringName)


func _ready() -> void:
	animation_player.animation_finished.connect(animation_finished.emit)


func has_anim(animation: StringName) -> bool:
	if not is_instance_valid(animation_player):
		return false
	
	return animation_player.has_animation(animation)


func play_anim(animation: StringName, force: bool = false) -> void:
	if not has_anim(animation):
		return
	if animation_player.current_animation == animation and not force:
		return
	
	last_animation = animation
	animation_player.play(animation)


func dance(force: bool = false) -> void:
	dance_step = wrapi(dance_step + 1, 0, dance_steps.size())
	play_anim(dance_steps[dance_step], force)
