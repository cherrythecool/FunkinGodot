@tool
extends CreditsContributor


@onready var texture_rect: TextureRect = %texture
@onready var label: Label = %label
var starting_stretch_mode: TextureRect.StretchMode
var starting_texture_filter: CanvasItem.TextureFilter


func _ready() -> void:
	starting_stretch_mode = texture_rect.stretch_mode
	starting_texture_filter = texture_rect.texture_filter


func _physics_process(_delta: float) -> void:
	if target_y == 0:
		texture_rect.position = (
			Vector2(8.0, 56.0) +
			Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		)
	else:
		texture_rect.position = Vector2(8.0, 56.0)


func _process(delta: float) -> void:
	super(delta)

	if target_y == 0:
		label.material = material
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		label.material = null
		texture_rect.stretch_mode = starting_stretch_mode
		texture_rect.texture_filter = starting_texture_filter
