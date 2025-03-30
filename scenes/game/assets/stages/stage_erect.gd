extends Stage


func hue_sprite(sprite: CanvasItem, hue: float, sat: float, cont: float, bright: float) -> void:
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = load('uid://bgwusoh6kicj3')
	sprite.material.set_shader_parameter('hue', hue)
	sprite.material.set_shader_parameter('saturation', sat)
	sprite.material.set_shader_parameter('contrast', cont)
	sprite.material.set_shader_parameter('brightness', bright)


func _ready() -> void:
	game.player._camera_offset.position += Vector2(-50.0, -50.0)
	game.opponent._camera_offset.position += Vector2(210.0, 15.0)
	game.player.z_index += 300
	game.opponent.z_index += 200
	game.spectator.z_index += 100
	hue_sprite(game.player.get_node(^'sprite'), 12.0, 0.0, 7.0, -23.0)
	hue_sprite(game.spectator.get_node(^'sprite'), -9.0, 0.0, -4.0, -30.0)
	if game.spectator.has_node(^'speakers'):
		hue_sprite(game.spectator.get_node(^'speakers'), -9.0, 0.0, -4.0, -30.0)
	hue_sprite(game.opponent.get_node(^'sprite'), -33.0, 0.0, -23.0, -33.0)
