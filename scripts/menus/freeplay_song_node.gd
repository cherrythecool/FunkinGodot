@tool
class_name FreeplaySongNode extends ListedAlphabet


var song: FreeplaySong


func _process(delta: float) -> void:
	super._process(delta)
	visible = global_position.y > -size.y - 50.0 and global_position.y < 770.0
