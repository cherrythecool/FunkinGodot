extends FunkinScript


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &"playanimation":
		return

	var data: Dictionary = event.data[0]
	var target: String = data.get("target", "bf")
	var animation: String = data.get("anim", "hey")
	var character: Character
	match target:
		"bf", "boyfriend":
			character = player
		"gf", "girlfriend":
			character = spectator
		"dad":
			character = opponent
	if not is_instance_valid(character):
		push_warning("Couldn't find character name \"%s\" in PlayAnimation event." % [target,])
		return

	character.play_anim(animation, true, true)
