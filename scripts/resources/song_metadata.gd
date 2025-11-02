class_name SongMetadata extends Resource


@export var display_name: StringName = &'Song Name'
@export var mix: StringName = &'Default'
@export var icon: Icon = null

@export var difficulties: PackedStringArray = [
	'easy', 'normal', 'hard',
]
@export var difficulty_song_overrides: Dictionary[String, StringName] = {}


func get_full_name() -> StringName:
	if mix != &'Default':
		return &'%s [%s Mix]' % [display_name, mix]

	return display_name
