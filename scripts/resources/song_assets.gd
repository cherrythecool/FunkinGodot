extends Resource
class_name SongAssets


@export_group("Art")

@export var player: PackedScene = null
@export var spectator: PackedScene = null
@export var opponent: PackedScene = null

@export var stage: PackedScene = null

@export_group("HUD")

@export var hud: PackedScene = null
@export var hud_skin: HUDSkin = null

@export_subgroup("Note Skins")
@export var player_note_skin: NoteSkin = null
@export var opponent_note_skin: NoteSkin = null

@export_group("Miscellaneous")

@export var scripts: Array[PackedScene] = []
@export var note_types: Dictionary[StringName, PackedScene] = {}


func get_player() -> PackedScene:
	if is_instance_valid(player):
		return player
	return load("uid://bu44d2he2dxm3")


func get_opponent() -> PackedScene:
	if is_instance_valid(opponent):
		return opponent
	return load("uid://cdlt4jc7j8122")


func get_spectator() -> PackedScene:
	if is_instance_valid(spectator):
		return spectator
	return load("uid://bragoy3tisav2")


func get_stage() -> PackedScene:
	if is_instance_valid(stage):
		return stage
	return load("uid://0ih6j18ov417")


func get_hud_skin() -> HUDSkin:
	if is_instance_valid(hud_skin):
		return hud_skin
	return load("uid://oxo327xfxemo")


func get_hud() -> PackedScene:
	if is_instance_valid(hud):
		return hud
	return load("uid://cr0c14kq4sye1")
