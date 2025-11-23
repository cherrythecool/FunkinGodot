extends FunkinScript


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &"animation name":
		return

	# Do your event logic here!
