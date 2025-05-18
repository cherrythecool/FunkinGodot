extends Node2D


@onready var backdrop: Node2D = $backdrop
@onready var left: Node2D = $left
@onready var center: Node2D = $center
@onready var right: Node2D = $right

var last_props: StoryWeekProps = null
var props: Array[Node] = []


func update_props(assets: StoryWeekProps) -> void:
	var force_reload: bool = (not is_instance_valid(last_props))
	if force_reload or last_props.backdrop != assets.backdrop:
		Global.free_children_from(backdrop)
		if is_instance_valid(assets.backdrop):
			_add_prop_to(backdrop, assets.backdrop)

	if force_reload or last_props.left != assets.left:
		Global.free_children_from(left)
		if is_instance_valid(assets.left):
			_add_prop_to(left, assets.left)

	if force_reload or last_props.center != assets.center:
		Global.free_children_from(center)
		if is_instance_valid(assets.center):
			_add_prop_to(center, assets.center)

	if force_reload or last_props.right != assets.right:
		Global.free_children_from(right)
		if is_instance_valid(assets.right):
			_add_prop_to(right, assets.right)

	props = [null, null, null, null]
	_update_props_array(backdrop, 0)
	_update_props_array(left, 1)
	_update_props_array(center, 2)
	_update_props_array(right, 3)

	last_props = assets


func beat_hit() -> void:
	var children: Array[Node] = left.get_children()
	children.append_array(center.get_children())
	children.append_array(right.get_children())

	for child: StoryMenuProp in children:
		child.dance()


func _add_prop_to(parent: Node, prop: PackedScene) -> void:
	var prop_node: StoryMenuProp = prop.instantiate()
	parent.add_child(prop_node)
	props.push_back(prop_node)


func _update_props_array(node: Node, index: int) -> void:
	if node.get_child_count() > 0:
		props[index] = node.get_child(0)
