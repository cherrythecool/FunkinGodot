extends BaseOptionsSection


@export var max_y: float = 160.0
@onready var the_list: Node2D = $the_list
@onready var options: Node2D = the_list.get_node(^'options')
var selected_option: Option


func _activate() -> void:
	super()
	change_selection()
	_update_items(1.0)


func _process(delta: float) -> void:
	if not (active and alive):
		return

	_update_items(delta)

	if is_instance_valid(selected_option):
		delta = minf(delta, 0.25)
		var target: float = clampf(selected_option.position.y, 0.0, max_y)
		the_list.position.y = lerpf(the_list.position.y, -184.0 - target, delta * 4.0)


func _input(event: InputEvent) -> void:
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
		selected_option._select()


func change_selection(amount: int = 0) -> void:
	options.get_child(selected)._unfocus()
	selected = wrapi(selected + amount, 0, options.get_child_count())
	selected_option = options.get_child(selected)
	selected_option._focus()

	if amount != 0:
		GlobalAudio.get_player(^'MENU/SCROLL').play()


func _update_items(delta: float) -> void:
	# 0.0714 ~~ 1 / 14 aka the max amount of delta allowed in our lerpfs
	delta = minf(delta, 0.0714)

	for i: int in options.get_child_count():
		var target_alpha: float = 1.0 if i == selected else 0.5
		var child: Node2D = options.get_child(i) as Node2D
		child.modulate.a = lerpf(child.modulate.a, target_alpha, delta * 14.0)
