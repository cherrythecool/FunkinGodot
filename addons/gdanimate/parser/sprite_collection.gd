class_name SpriteCollection extends Resource


@export var map: Dictionary[StringName, CollectedSprite] = {}
@export var size: Vector2i = Vector2i.ZERO
@export var texture: Texture2D


static func load_from_json(input: Dictionary, texture: Texture2D) -> SpriteCollection:
	var collection := SpriteCollection.new()
	collection.texture = texture
	
	var atlas: Dictionary = input.get('ATLAS', {})
	var sprites: Array = atlas.get('SPRITES', [])
	
	var image: Image = null
	for sprite: Dictionary in sprites:
		var values: Dictionary = sprite.get('SPRITE', {})
		if values.is_empty():
			continue
		
		var collected := CollectedSprite.new()
		collected.rect = Rect2i(Vector2i(values.get('x', 0), values.get('y', 0)),
				Vector2i(values.get('w', 0), values.get('h', 0)))
		collected.rotated = values.get('rotated', false)
		
		var name := StringName(values.get('name', ''))
		## TODO: make this less hacky of a fix :p
		if collected.rotated:
			if not is_instance_valid(image):
				image = collection.texture.get_image()
				if image.is_compressed():
					image.decompress()
			
			var frame := image.get_region(collected.rect)
			frame.rotate_90(COUNTERCLOCKWISE)
			var image_texture := ImageTexture.create_from_image(frame)
			collected.custom_texture = image_texture
		
		collection.map.set(name, collected)
	
	var metadata: Dictionary = input.get('meta', {})
	if metadata.has('size'):
		var raw_size: Dictionary = metadata.get('size', {})
		collection.size = Vector2i(raw_size.get('w', 0), raw_size.get('h', 0))
	
	return collection
