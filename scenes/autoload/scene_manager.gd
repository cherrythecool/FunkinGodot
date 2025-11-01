extends CanvasLayer


var current_path: String = ''

@onready var transition: ColorRect = $transition
var tween: Tween

signal scene_changed()


func _ready() -> void:
	transition.material.set_shader_parameter('progress', 0.0)
	visible = false


func switch_to(scene: PackedScene, use_transition: bool = true) -> void:
	if not Config.get_value('interface', 'scene_transitions'):
		use_transition = false

	var tree: SceneTree = get_tree()
	var killed: bool = is_instance_valid(tween) and tween.is_running()
	if killed:
		tween.kill()

	if use_transition:
		tree.current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		visible = true
		tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(transition.material, 'shader_parameter/progress', 1.0, 0.5)
		tween.tween_callback(func() -> void:
			if is_instance_valid(tween) and tween.is_running():
				tween.kill()

			tree.change_scene_to_packed.call_deferred(scene)
			scene_changed.emit()

			tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(transition.material, 'shader_parameter/progress', 0.0, 0.5)
			tween.tween_callback(func() -> void:
				visible = false)
		)
	else:
		if killed:
			transition.material.set_shader_parameter('progress', 0.0)
			visible = false

		tree.change_scene_to_packed.call_deferred(scene)
		scene_changed.emit()
