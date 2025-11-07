class_name Rating extends Resource


@export var name: StringName = &"marvelous"
@export_range(0.0, 180.0, 0.01) var timing: float = 22.5
@export_range(0, 1000, 1, "or_less") var score: int = 350
@export_range(0.0, 2.0, 0.01, "or_less") var health: float = 1.15
