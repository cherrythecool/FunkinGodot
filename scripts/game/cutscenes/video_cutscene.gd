## Simple cutscene that plays a video with a
## [VideoStreamPlayer] and then lets you play.
class_name VideoCutscene extends BaseCutscene

signal on_video_ended

## Whether or not to hide the game and its hud
## while the video is playing.
@export var hide_game: bool = true

## Whether or not to allow players to skip the
## cutscene by pressing enter or space (action ui_accept).
@export var allow_skipping: bool = true

## Whether to autoplay the video once its stream is set
@export var autoplay: bool = true

@onready var video_player: VideoStreamPlayer = %video_player

func _ready() -> void:
	super()

	if autoplay:
		play()
	if game and hide_game:
		game.visible = false
		game.hud.visible = false


func _input(event: InputEvent) -> void:
	if not allow_skipping:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action(&"ui_accept"):
		finish()

## Plays the video if it isn't already playing.[br]
## [param]force[/param] To force the video to play regardless of whether it is already.
func play(force: bool = false) -> void:
	if video_player.is_playing():
		if not force:
			return
		video_player.stop()
	video_player.show()
	video_player.play()

## Frees the cutscene and shows the game again
## if it was previously hidden.
func finish() -> void:
	super()

	if video_player.is_playing():
		video_player.stop()
	video_player.hide()
	on_video_ended.emit()

	if game and hide_game:
		game.visible = true
		game.hud.visible = true
