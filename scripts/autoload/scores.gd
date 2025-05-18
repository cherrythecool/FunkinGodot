extends Node


var data: Dictionary


func _ready() -> void:
	data = _load_user_data()
	save()


# Saving and loading file #

func _load_user_data() -> Dictionary:
	if not FileAccess.file_exists('user://scores.res'):
		return {}

	var file: FileAccess = FileAccess.open('user://scores.res', FileAccess.READ)
	return file.get_var()


func save() -> void:
	var file: FileAccess = FileAccess.open('user://scores.res', FileAccess.WRITE)
	file.store_var(data)

# Getting and setting scores #

func _get_score_key(song: StringName, difficulty: StringName) -> String:
	return '%s/%s' % [song, difficulty]


func get_score(song: StringName, difficulty: StringName) -> Dictionary:
	return data.get(_get_score_key(song, difficulty), {
			'score': 'N/A',
			'misses': 'N/A',
			'accuracy': 'N/A',
			'rank': 'N/A',
		})


func has_score(song: StringName, difficulty: StringName) -> bool:
	return data.has(_get_score_key(song, difficulty))


func set_score(song: StringName, difficulty: StringName, score: Dictionary) -> void:
	data[_get_score_key(song, difficulty)] = score
	save()


func reset_score(song: StringName, difficulty: StringName) -> void:
	data.erase(_get_score_key(song, difficulty))
	save()
