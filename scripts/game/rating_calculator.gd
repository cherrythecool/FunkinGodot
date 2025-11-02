class_name RatingCalculator extends Node


@export var ranks: Dictionary[float, StringName] = {
	0.0: &'F',
	50.0: &'F+',
	60.0: &'D',
	70.0: &'C',
	80.0: &'B',
	90.0: &'A',
	95.0: &'S',
	100.0: &'S+',
}

@export var ratings: Array[Rating] = []

@export var accuracy_curve: Curve
var hit_count: int = 0

var accuracy: float:
	get = get_accuracy
var total_accuracy: float = 0.0

var rank: String:
	get = get_rank


func add_hit(difference: float, hit_window: float) -> void:
	hit_count += 1
	total_accuracy += clampf(
		accuracy_curve.sample(difference / hit_window),
		0.0,
		1.0,
	)


func get_rating(difference: float) -> Rating:
	if ratings.is_empty():
		return null

	var returned_rating: Rating = ratings[0]
	for rating: Rating in ratings:
		if difference <= rating.timing / 1000.0:
			returned_rating = rating
		else:
			break

	return returned_rating


func get_accuracy() -> float:
	if hit_count <= 0:
		return 0.0

	return total_accuracy / float(hit_count) * 100.0


func get_rank() -> StringName:
	var value: StringName = &'N/A'
	var current_accuracy: float = accuracy
	for accuracy_minimum: float in ranks.keys():
		if current_accuracy >= accuracy_minimum:
			value = ranks[accuracy_minimum]
			continue
		else:
			break
	
	return value
