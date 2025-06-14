extends Character


@onready var speakers: AnimatedSprite = $speakers


func set_character_material(new_material: Material) -> void:
	super(new_material)
	speakers.material = new_material
