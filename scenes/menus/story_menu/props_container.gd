extends Node
class_name StoryModePropsContainer


@onready var backdrop: Node2D = $backdrop
@onready var left: Node2D = $left
@onready var center: Node2D = $center
@onready var right: Node2D = $right

var last_props: StoryWeekProps = null
var props: Array[Node] = []
var prop_tweens: Array[Tween] = [null, null, null, null]


func update_props(assets: StoryWeekProps) -> void:
	var force_reload: bool = (not is_instance_valid(last_props))
	if force_reload or last_props.backdrop != assets.backdrop:
		GameUtils.free_children_from(backdrop)
		if is_instance_valid(assets.backdrop):
			add_prop_to(backdrop, assets.backdrop)

	if force_reload or last_props.left != assets.left:
		GameUtils.free_children_from(left)
		if is_instance_valid(assets.left):
			add_prop_to(left, assets.left)

	if force_reload or last_props.center != assets.center:
		GameUtils.free_children_from(center)
		if is_instance_valid(assets.center):
			add_prop_to(center, assets.center)

	if force_reload or last_props.right != assets.right:
		GameUtils.free_children_from(right)
		if is_instance_valid(assets.right):
			add_prop_to(right, assets.right)

	props = [null, null, null, null]

	update_props_array(backdrop, 0)
	update_props_array(left, 1)
	update_props_array(center, 2)
	update_props_array(right, 3)

	last_props = assets


func beat_hit() -> void:
	var children: Array[Node] = left.get_children()
	children.append_array(center.get_children())
	children.append_array(right.get_children())

	for child: StoryMenuProp in children:
		child.dance()


func add_prop_to(parent: Node, prop: PackedScene) -> void:
	var prop_node: StoryMenuProp = prop.instantiate()
	parent.add_child(prop_node)


func update_props_array(node: Node, index: int) -> void:
	if node.get_child_count() > 0:
		props[index] = node.get_child(0)


func tween_prop_in(index: int) -> void:
	var parent: Node2D
	match index:
		0:
			parent = backdrop
		1:
			parent = left
		2:
			parent = center
		3:
			parent = right
	parent.position.y = 400.0
	
	if is_instance_valid(prop_tweens[index]) and prop_tweens[index].is_running():
		prop_tweens[index].kill()
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(parent, ^"position:y", 200.0, 0.5)
	prop_tweens[index] = tween


func tween_prop_out(index: int) -> void:
	var parent: Node2D
	match index:
		0:
			parent = backdrop
		1:
			parent = left
		2:
			parent = center
		3:
			parent = right
	
	if is_instance_valid(prop_tweens[index]) and prop_tweens[index].is_running():
		prop_tweens[index].kill()
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(parent, ^"position:y", 720.0, 1.5)
	prop_tweens[index] = tween
