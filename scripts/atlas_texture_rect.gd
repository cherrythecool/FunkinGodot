@tool
extends TextureRect
class_name AtlasTextureRect


@export var tile_x: bool = false
@export var tile_y: bool = true
@export var mirror_every_other: bool = false:
	set(value):
		mirror_every_other = value
		queue_redraw()


func _draw() -> void:
	if stretch_mode != STRETCH_TILE:
		return
	if not is_instance_valid(texture):
		return
	if texture is not AtlasTexture:
		return
	var item: RID = get_canvas_item()
	RenderingServer.canvas_item_clear(item)
	
	var atlas: AtlasTexture = texture as AtlasTexture
	if (not tile_x) and tile_y:
		var step: float = texture.get_height()
		var steps: int = int(size.y / step)
		var mirror_multiplier: float = 1.0
		var scaling: Vector2 = size / atlas.get_size()
		var offset: Vector2 = atlas.margin.position
		offset *= scaling
		
		for i: int in steps:
			draw_texture_rect_region(atlas.atlas,
				Rect2(
					Vector2(0.0, float(i) * step) + offset,
					Vector2(size.x, step) - (atlas.margin.size * scaling)
				),
				Rect2(
					atlas.region.position,
					atlas.region.size * Vector2(1.0, mirror_multiplier)
				),
			)
			
			if mirror_every_other:
				mirror_multiplier *= -1.0
		
		if size.y > steps * step:
			var src_region: Rect2 = Rect2(
				atlas.region.position,
				Vector2(
					atlas.region.size.x,
					(size.y - (float(steps) * step))
				),
			)
			
			if mirror_multiplier == -1.0:
				var tiled: float = (size.y - (float(steps) * step))
				src_region = Rect2(
					atlas.region.position + Vector2(
						0.0, (atlas.region.size.y - tiled)
					),
					Vector2(
						atlas.region.size.x,
						-tiled
					),
				)
			
			draw_texture_rect_region(atlas.atlas,
				Rect2(
					Vector2(0.0, (float(steps) * step)) + offset,
					Vector2(size.x, size.y - (float(steps) * step)) - (atlas.margin.size * scaling)
				),
				src_region,
			)
