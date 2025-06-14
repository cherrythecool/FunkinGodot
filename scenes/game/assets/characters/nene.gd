extends Character


@onready var speakers: AnimateSymbol = $speakers
@onready var eye_whites: ColorRect = $eye_whites
@onready var eyes: AnimateSymbol = $eyes
@onready var background: ColorRect = $background
var camera_side: int = 0



func _ready() -> void:
	super()
	if not is_instance_valid(Game.instance):
		return

	Game.instance.event_hit.connect(_on_event_hit)
	await Game.instance.ready_post
	eye_whites.material = speakers.material
	eyes.material = speakers.material
	background.material = speakers.material


func _process(_delta: float) -> void:
	if camera_side == 1 and eyes.frame >= 13:
		eyes.playing = false
		eyes.frame = 13


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &'camera pan':
		return

	var side: int = event.data[0]
	# prevent middle character from fucking with us :+1:
	if side != 0 and side != 1:
		return

	camera_side = side
	if event.time <= 0.0:
		if camera_side == 0:
			eyes.frame = 31
			eyes.playing = false
		else:
			eyes.frame = 13
			eyes.playing = false

		return

	if camera_side == 0:
		eyes.frame = 13
		eyes.playing = true
	else:
		eyes.frame = 0
		eyes.playing = true
