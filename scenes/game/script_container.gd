class_name ScriptContainer extends Node


func load_scripts(song: StringName, song_path: String = '') -> void:
	if song_path.is_empty():
		song_path = 'res://assets/songs'
	
	# Shouldn't be an issue but just to be sure.
	if song_path.ends_with('/'):
		song_path = song_path.left(song_path.length() - 1)
	
	var assets: SongAssets = load('%s/%s/assets.tres' % [song_path, song])
	if assets.scripts.is_empty():
		return
	
	for script: PackedScene in assets.scripts:
		if not is_instance_valid(script):
			continue
		
		var script_instance: Node = script.instantiate()
		add_child(script_instance)
