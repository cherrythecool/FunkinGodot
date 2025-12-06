class_name SongMetadata extends Resource


@export_group("Display Info")
@export var display_name: StringName = &"Song Name"
@export var mix: StringName = &"Default"
@export var icon: Icon = null

@export_group("Difficulties")
@export var difficulties: PackedStringArray = [
	"easy", "normal", "hard",
]
@export var difficulty_song_overrides: Dictionary[String, StringName] = {}

@export_group("Game Properties")
@export var skip_countdown: bool = false


func get_full_name() -> StringName:
	if mix != &"Default":
		return &"%s [%s Mix]" % [display_name, mix]

	return display_name
