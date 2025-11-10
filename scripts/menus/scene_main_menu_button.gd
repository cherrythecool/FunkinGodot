class_name SceneButton extends MainMenuButton


@export_file("*.tscn") var scene_path: String


func accept() -> bool:
	if not ResourceLoader.exists(scene_path):
		return super()
	
	SceneManager.switch_to(load(scene_path))
	return true
