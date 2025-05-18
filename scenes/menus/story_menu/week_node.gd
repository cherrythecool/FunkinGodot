class_name StoryWeekNode extends TextureRect


@export var songs: PackedStringArray
@export var difficulties: PackedStringArray

@export_category('Visuals')
@export var display_name: StringName
@export var background_color: Color = Color('#f9cf51')
@export var props: StoryWeekProps

@export_category('Advanced')
@export var difficulty_suffixes: DifficultyMap = DifficultyMap.new()


func get_song_name(index: int, difficulty: StringName) -> StringName:
	if is_instance_valid(difficulty_suffixes) and difficulty_suffixes.mapping.has(difficulty):
		return songs[index] + difficulty_suffixes.mapping.get(difficulty, &'')

	return songs[index]
