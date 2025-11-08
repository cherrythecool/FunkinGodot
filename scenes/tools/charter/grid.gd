@tool
extends Control


@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY

@export var columns: int = 8
@export var rows: int = 16

var grid_size: Vector2:
	get():
		return size / Vector2(columns, rows)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	if Conductor.instance.active:
		queue_redraw()


func _draw() -> void:
	for x in columns:
		for y in rows:
			var color: Color = primary_color
			if (x + y) % 2 == 0:
				color = secondary_color
			draw_rect(Rect2(
				Vector2(
					x * grid_size.x,
					y * grid_size.y,
				),
				grid_size,
			), color)
