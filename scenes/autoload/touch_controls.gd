extends CanvasLayer


@onready var menus: Control = %menus
@onready var freeplay: Control = %freeplay
@onready var game: Control = %game

@onready var left: ColorRect = %left
@onready var down: ColorRect = %down
@onready var up: ColorRect = %up
@onready var right: ColorRect = %right

@onready var rects: Array[ColorRect] = [left, down, up, right]
var states: Array[bool] = [false, false, false, false]


func _ready() -> void:
	if (not DisplayServer.is_touchscreen_available()) or not OS.has_feature('mobile'):
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
		if states[i]:
			rects[i].color.a = 0.3
		else:
			rects[i].color.a = lerpf(rects[i].color.a, 0.0, delta * 6.0)

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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game.visible:
			fake_input('pause_game')
			fake_input('pause_game', false)
		else:
			fake_input('ui_cancel')
			fake_input('ui_cancel', false)


func fake_input(action: String, press: bool = true) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = press
	Input.parse_input_event(ev)
