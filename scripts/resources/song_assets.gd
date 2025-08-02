class_name SongAssets extends Resource


@export_category('Art')

@export var player: PackedScene = null
@export var spectator: PackedScene = null
@export var opponent: PackedScene = null

@export var stage: PackedScene = null

@export_category('HUD')

@export var hud: PackedScene = null
@export var hud_skin: HUDSkin = null

@export var player_skin: NoteSkin = null
@export var opponent_skin: NoteSkin = null

@export_category('Misc')

@export var scripts: Array[PackedScene] = []


func get_player() -> PackedScene:
	if is_instance_valid(player):
		return player
	return load('uid://bu44d2he2dxm3')


func get_opponent() -> PackedScene:
	if is_instance_valid(opponent):
		return opponent
	return load('uid://cdlt4jc7j8122')


func get_spectator() -> PackedScene:
	if is_instance_valid(spectator):
		return spectator
	return load('uid://bragoy3tisav2')


func get_stage() -> PackedScene:
	if is_instance_valid(stage):
		return stage
	return load('uid://0ih6j18ov417')


func _to_string() -> String:
	return 'SongAssets(player: %s, opponent: %s, spectator: %s, stage: %s, scripts: %s)' \
			% [player, opponent, spectator, stage, scripts]
