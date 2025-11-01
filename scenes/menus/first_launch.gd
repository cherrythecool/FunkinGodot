extends Node2D


var options: Array[Node2D]
var selected: int = 0
var active: bool = true


func _ready() -> void:
	options = [$yes, $no]


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	
	if event.is_action('ui_left') or event.is_action('ui_right'):
		_change_selection(roundi(Input.get_axis('ui_left', 'ui_right')))
	if event.is_action('ui_up') or event.is_action('ui_down'):
		_change_selection(roundi(Input.get_axis('ui_up', 'ui_down')))
	if event.is_action('ui_accept'):
		active = false
		GlobalAudio.get_player('MENU/CONFIRM').play()
		
		match selected:
			0:
				OptionsMenu.target_scene = 'scenes/menus/title_screen.tscn'
				SceneManager.switch_to(load('res://scenes/menus/options_menu.tscn'))
			1:
				SceneManager.switch_to(load('res://scenes/menus/title_screen.tscn'))
	if event.is_action('ui_cancel'):
		active = false
		GlobalAudio.get_player('MENU/CANCEL').play()
		SceneManager.switch_to(load('scenes/menus/title_screen.tscn'))


func _change_selection(amount: int = 0) -> void:
	options[selected].modulate.a = 0.5
	selected = wrapi(selected + amount, 0, options.size())
	options[selected].modulate.a = 1.0
	
	if amount != 0:
		GlobalAudio.get_player('MENU/SCROLL').play()
