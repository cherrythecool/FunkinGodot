class_name BaseOptionsSection extends Node2D


var selected: int = 0
var alive: bool = false:
	set(value):
		visible = value
		
		if value:
			_activate()
	get:
		return visible
var active: bool = true


func _ready() -> void:
	alive = true


func _input(event: InputEvent) -> void:
	if not (active and alive):
		return
	if not event.is_pressed():
		return
	if event.is_action(&'ui_cancel'):
		get_viewport().set_input_as_handled()
		active = false
		get_tree().current_scene.deselect_current()
		return


func _activate() -> void:
	pass


func _on_timer_timeout() -> void:
	active = true
