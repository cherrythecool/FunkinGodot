extends Node


@onready var music: AudioStreamPlayer = get_player(^"MUSIC")


func get_player(path: NodePath) -> AudioStreamPlayer:
	var player: Node = get_node_or_null(path)
	if player is not AudioStreamPlayer:
		printerr("GlobalAudio: Node you provided exists but is not AudioStreamPlayer")
		return null

	return player
