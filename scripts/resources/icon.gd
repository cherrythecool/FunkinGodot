class_name Icon extends Resource


@export var texture: Texture2D = null
@export var color: Color = Color('a1a1a1')
@export var frames: Vector2i = Vector2i(2, 1)
@export var filter: CanvasItem.TextureFilter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE


static func create_sprite(icon: Icon) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = icon.texture
	if not is_instance_valid(sprite.texture):
		sprite.texture = load('uid://bk7jsl1s5ax2o')

	sprite.hframes = icon.frames.x
	sprite.vframes = icon.frames.y
	sprite.texture_filter = icon.filter

	return sprite
