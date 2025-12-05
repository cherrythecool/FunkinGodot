@tool
extends Control


# Returns a boolean by examining the data being dragged to see if it's valid
# to drop here.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("files") and data["files"] is Array


# Takes the data being dragged and processes it. In this case, we are
# assigning a new color to the target color picker button.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	print(data)
