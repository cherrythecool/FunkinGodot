extends CanvasLayer


@onready var menus: Control = %menus
@onready var freeplay: Control = %freeplay
@onready var game: Control = %game

@onready var left: ColorRect = %left
@onready var down: ColorRect = %down
@onready var up: ColorRect = %up
@onready var right: ColorRect = %right

@onready var rects: Array[ColorRect] = [left, down, up, right,]
var states: Array[bool] = [false, false, false, false,]


func _ready() -> void:
	if (not DisplayServer.is_touchscreen_available()) or not Config.get_value('gameplay', 'use_touch'):
		queue_free()
		return

	for i: int in rects.size():
		var rect: ColorRect = rects[i]
		var button: TouchScreenButton = rect.get_node(^'button')
		button.pressed.connect(func() -> void:
			states[i] = true
		)
		button.released.connect(func() -> void:
			states[i] = false
		)


func _process(delta: float) -> void:
	for i: int in states.size():
		rects[i].color.a = lerpf(rects[i].color.a, 0.5 * float(states[i]), delta * 6.0)

	var tree: SceneTree = get_tree()
	if (not is_instance_valid(tree)) or not is_instance_valid(tree.current_scene):
		return

	var current: Node = get_tree().current_scene
	if current is Game and current.process_mode == Node.PROCESS_MODE_DISABLED:
		menus.visible = true
	else:
		menus.visible = current is not Game
	freeplay.visible = current is FreeplayMenu
	game.visible = not menus.visible


func fake_input(action: String, press: bool = true) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = press
	Input.parse_input_event(ev)


func _on_left_pressed() -> void:
	fake_input('ui_left')
	fake_input('ui_left', false)


func _on_down_pressed() -> void:
	fake_input('ui_down')
	fake_input('ui_down', false)


func _on_up_pressed() -> void:
	fake_input('ui_up')
	fake_input('ui_up', false)


func _on_right_pressed() -> void:
	fake_input('ui_right')
	fake_input('ui_right', false)


func _on_cancel_pressed() -> void:
	fake_input('ui_cancel')
	fake_input('ui_cancel', false)


func _on_accept_pressed() -> void:
	fake_input('ui_accept')
	fake_input('ui_accept', false)


func _on_shift_pressed() -> void:
	fake_input('freeplay_open_characters')
	fake_input('freeplay_open_characters', false)


func _on_pause_pressed() -> void:
	fake_input('pause_game')
	fake_input('pause_game', false)
