class_name Category extends Control


@export var category: PackedScene = null
@onready var sprite: AnimatedSprite = $sprite

var target_alpha: float = 0.6
var target_scale: float = 0.8


func _ready() -> void:
	if category == null:
		category = load('res://scenes/menus/options/sections/no_section.tscn')
	
	sprite.modulate.a = target_alpha
	sprite.scale = Vector2(target_scale, target_scale)


func _process(delta: float) -> void:
	sprite.modulate.a = lerpf(sprite.modulate.a, target_alpha, delta * 9.0)
	sprite.scale = sprite.scale.lerp(Vector2(target_scale, target_scale), delta * 10.0)
