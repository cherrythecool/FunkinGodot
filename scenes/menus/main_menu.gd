class_name MainMenu extends Node2D


static var selected: int = 0
static var freeplay_scene: String = 'uid://3rua2gpac5p8'

@onready var items: VBoxContainer = $ui_layer/scroll_container/container
@onready var version_label: Label = $ui_layer/version_label
@onready var background_animations: AnimationPlayer = $background/animation_player
@onready var camera: Camera2D = %camera
@onready var timer: Timer = %timer

var active: bool = true


func _ready() -> void:
	if not GlobalAudio.music.playing:
		GlobalAudio.music.play()

	version_label.text = version_label.text.replace('$VERSION', Global.version)
	change_selection()


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if not active:
		return
	if event.is_action('ui_down') or event.is_action('ui_up'):
		change_selection(roundi(Input.get_axis('ui_up', 'ui_down')))
	if event.is_action('ui_cancel'):
		GlobalAudio.get_player('MENU/CANCEL').play()
		active = false
		SceneManager.switch_to(load('res://scenes/menus/title_screen.tscn'))
	if event.is_action('ui_accept'):
		GlobalAudio.get_player('MENU/CONFIRM').play()
		active = false
		_press_animation()

		var item: MainMenuButton = items.get_child(selected) as MainMenuButton
		item.press()
		timer.start(0.0)

		for connection: Dictionary in timer.timeout.get_connections():
			if connection.callable == null:
				continue

			timer.timeout.disconnect(connection.callable)
		timer.timeout.connect(_on_press.bind(item))


func _on_press(item: MainMenuButton) -> void:
	if not item.accept():
		GlobalAudio.get_player('MENU/CANCEL').play()
		active = true
		_cancel_animation()


func _press_animation() -> void:
	if Config.get_value('accessibility', 'flashing_lights'):
		background_animations.play(&'loop')
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()

	for i: int in items.get_child_count():
		if i == selected:
			continue

		tween.tween_property(items.get_child(i), 'modulate:a', 0.0, 0.25)


func _cancel_animation() -> void:
	background_animations.seek(0.0, true)
	background_animations.stop()

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT).set_parallel()

	for i: int in items.get_child_count():
		if i == selected:
			continue

		tween.tween_property(items.get_child(i), 'modulate:a', 1.0, 0.25)


func change_selection(amount: int = 0) -> void:
	var previous_item: MainMenuButton = items.get_child(selected) as MainMenuButton
	previous_item.z_index = 0
	previous_item.sprite.play('%s idle' % previous_item.animation_name)
	selected = wrapi(selected + amount, 0, items.get_child_count())

	var current_item: MainMenuButton = items.get_child(selected) as MainMenuButton
	current_item.z_index = 1
	current_item.sprite.play('%s selected' % current_item.animation_name)
	camera.position.y = current_item.global_position.y

	if amount != 0:
		GlobalAudio.get_player('MENU/SCROLL').play()
