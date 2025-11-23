extends Character


func play_anim(anim: StringName, force: bool = false, special: bool = false) -> void:
	super(anim, force, special)


func sing(note: Note, force: bool = false) -> void:
	super(note, force)


func sing_miss(note: Note, force: bool = false) -> void:
	super(note, force)


func dance(force: bool = false) -> void:
	super(force)


func set_character_material(new_material: Material) -> void:
	super(new_material)
	
	# Maybe use for custom logic if you have more sprites?
