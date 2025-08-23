class_name ScriptContainer extends Node


func load_scripts(song: StringName, song_path: String = '') -> void:
	if song_path.is_empty():
		song_path = 'res://assets/songs'

	# Shouldn't be an issue but just to be sure.
	if song_path.ends_with('/'):
		song_path = song_path.left(song_path.length() - 1)

	# Load scripts from res://assets/songs/song_name/scripts
	# by default, just like tracks, for convenience.
	var loaded_from_dir: Array[PackedScene] = []
	var script_path: String = '%s/%s/scripts' % [song_path, song]
	var files: PackedStringArray = ResourceLoader.list_directory(script_path)
	if not files.is_empty():
		for file: String in files:
			var resource: Resource = load('%s/%s' % [script_path, file])
			if resource is PackedScene:
				var script: PackedScene = resource as PackedScene
				var script_instance: Node = script.instantiate()
				add_child(script_instance)
				loaded_from_dir.push_back(script)

	var assets: SongAssets = load('%s/%s/assets.tres' % [song_path, song])
	if assets.scripts.is_empty():
		return

	for script: PackedScene in assets.scripts:
		if not is_instance_valid(script):
			continue
		if loaded_from_dir.has(script):
			continue

		var script_instance: Node = script.instantiate()
		add_child(script_instance)