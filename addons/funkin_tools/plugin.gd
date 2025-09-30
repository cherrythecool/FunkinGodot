@tool
extends EditorPlugin


var main_screen: Control


func _enter_tree() -> void:
	main_screen = load("uid://c1hkc3byawumw").instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_screen)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(main_screen):
		main_screen.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(main_screen):
		main_screen.visible = visible


func _get_plugin_name() -> String:
	return "Funkin' Tools"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("GDScript", "EditorIcons")
