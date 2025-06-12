class_name PreviewOption extends Option


@export_file('*.tscn') var PREVIEW: String = 'res://scenes/menus/options/previews/keybinds.tscn'
@export var current_preview: Node
var packed: PackedScene
var current: Node


func _ready() -> void:
	if not PREVIEW.is_empty():
		packed = load(PREVIEW)


func _focus() -> void:
	# if u get this... how????
	if is_instance_valid(current):
		return
	if not is_instance_valid(packed):
		return

	current = packed.instantiate()
	current_preview.add_child(current)


func _unfocus() -> void:
	if is_instance_valid(current):
		current.queue_free()
