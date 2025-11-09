class_name Icon extends Resource


@export var texture: Texture2D = null
@export var color: Color = Color("31B0D1")
@export var frames: Vector2i = Vector2i(2, 1)
@export var filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export_custom(PROPERTY_HINT_LINK, "") var internal_scale: Vector2 = Vector2.ONE


static func create_sprite(icon: Icon) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = icon.texture
	if not is_instance_valid(sprite.texture):
		sprite.texture = load("uid://dp4wr3woulw3y")

	sprite.hframes = icon.frames.x
	sprite.vframes = icon.frames.y
	sprite.texture_filter = icon.filter
	sprite.scale = icon.internal_scale

	return sprite
