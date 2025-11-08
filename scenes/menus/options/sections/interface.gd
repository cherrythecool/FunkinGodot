extends BaseOptionsSection


@export var options: Array[Option] = []
@export var max_distance: float = 200.0

@onready var selected_option: Option


func _activate() -> void:
	super()
	change_selection()
	_update_items(1.0)


func _process(delta: float) -> void:
	if not (active and alive):
		return

	_update_items(delta)


func change_selection(amount: int = 0) -> void:
	options[selected]._unfocus()
	selected = wrapi(selected + amount, 0, options.size())
	selected_option = options[selected]
	selected_option._focus()

	if amount != 0:
		GlobalAudio.get_player(^'MENU/SCROLL').play()


func _input(event: InputEvent) -> void:
	if options.is_empty():
		return
	if not (active and alive):
		return
	if not event.is_pressed():
		return
	if event.is_echo():
		return

	super(event)

	if event.is_action(&'ui_up') or event.is_action(&'ui_down'):
		change_selection(roundi(Input.get_axis(&'ui_up', &'ui_down')))
	if event.is_action(&'ui_accept'):
		get_viewport().set_input_as_handled()
		selected_option._select()


func _update_items(delta: float) -> void:
	# 0.0714 ~~ 1 / 14 aka the max amount of delta allowed in our lerpfs
	delta = minf(delta, 0.0714)
	position.y = lerpf(
			position.y,
			clampf(-selected_option.position.y, -max_distance, 0.0),
			delta * 4.0)

	for i: int in options.size():
		var target_alpha: float = 1.0 if i == selected else 0.5
		var child: Node2D = options[i] as Node2D
		child.modulate.a = lerpf(child.modulate.a, target_alpha, delta * 14.0)
