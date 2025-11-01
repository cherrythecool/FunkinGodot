class_name FreeplayButton extends MainMenuButton


func accept() -> bool:
	if not ResourceLoader.exists(MainMenu.freeplay_scene):
		return super()

	SceneManager.switch_to(load(MainMenu.freeplay_scene))
	return true
