extends Node


var fullscreened: bool = false:
	set(value):
		if not Engine.is_embedded_in_editor():
			main_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if value else Window.MODE_WINDOWED
		fullscreened = value

var game_size: Vector2:
	get:
		return get_viewport().get_visible_rect().size

var was_paused: bool = false
var main_window: Window = null


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	# Clear color without effect in editor.
	RenderingServer.set_default_clear_color(Color.BLACK)

	# Slightly lower input latency. (probably)
	Input.use_accumulated_input = false

	# Might save a small amount of performance.
	# Shouldn't be detrimental to this game specifically so...
	PhysicsServer2D.set_active(false)
	PhysicsServer3D.set_active(false)

	main_window = get_window()
	main_window.focus_entered.connect(_on_focus_enter)
	main_window.focus_exited.connect(_on_focus_exit)

	Config.loaded.connect(_on_config_loaded)
	Config.value_changed.connect(_on_value_changed)


func _on_focus_enter() -> void:
	if not Config.get_value('performance', 'auto_pause'):
		return
	get_tree().paused = false


func _on_focus_exit() -> void:
	if not Config.get_value('performance', 'auto_pause'):
		return

	var tree: SceneTree = get_tree()
	was_paused = tree.paused
	tree.paused = true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action('menu_fullscreen'):
		get_viewport().set_input_as_handled()
		fullscreened = not fullscreened
		return
	var tree: SceneTree = get_tree()
	if event.is_action('menu_reload') and is_instance_valid(tree) \
			and is_instance_valid(tree.current_scene):
		tree.reload_current_scene()
		tree.paused = false
		return


func _on_value_changed(section: String, key: String, value: Variant) -> void:
	if value == null:
		return
	if section != 'performance':
		return
	match key:
		'fps_cap':
			Engine.max_fps = value
		'vsync_mode':
			match value:
				'enabled':
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				'adaptive':
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
				'mailbox':
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
				_:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_config_loaded() -> void:
	_on_value_changed('performance', 'fps_cap',
			Config.get_value('performance', 'fps_cap'))
	_on_value_changed('performance', 'vsync_mode',
			Config.get_value('performance', 'vsync_mode'))


func free_children_from(node: Node, immediate: bool = false) -> void:
	for child: Node in node.get_children():
		if immediate:
			child.free()
		else:
			child.queue_free()


func free_from_array(nodes: Array[Node], immediate: bool = false) -> void:
	for child: Node in nodes:
		if not is_instance_valid(child):
			continue

		if immediate:
			child.free()
		else:
			child.queue_free()


# NOTE: this method is VERY hacky and likely to stop working
# at some point but i don't know of a better method rn? maybe
# i should make a godot pr :p
func get_rendering_api() -> String:
	var version: String = RenderingServer.get_video_adapter_api_version()
	if version.begins_with('12'):
		return 'D3D12'
	if version.begins_with('3'):
		return 'OpenGL'
	if version.begins_with('1'):
		return 'Vulkan'

	return 'Metal'
