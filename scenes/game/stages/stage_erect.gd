extends Stage


func hue_character(character: Character, hue: float, sat: float, cont: float, bright: float) -> void:
	var new_material: ShaderMaterial = ShaderMaterial.new()
	new_material.shader = load('uid://bgwusoh6kicj3')
	new_material.set_shader_parameter('hue', hue)
	new_material.set_shader_parameter('saturation', sat)
	new_material.set_shader_parameter('contrast', cont)
	new_material.set_shader_parameter('brightness', bright)
	character.set_character_material(new_material)


func _ready() -> void:
	game.player.offset_camera_position(Vector2(-50.0, -50.0))
	game.opponent.offset_camera_position(Vector2(210.0, 15.0))
	game.spectator.offset_camera_position(Vector2(0.0, -150.0))
	hue_character(game.player, 12.0, 0.0, 7.0, -23.0)
	hue_character(game.spectator, -9.0, 0.0, -4.0, -30.0)
	hue_character(game.opponent, -32.0, 0.0, -23.0, -33.0)
