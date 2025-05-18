class_name RatingsCalculator extends Node


@export var ratings: Array[Rating] = []


func get_rating(difference: float) -> Rating:
	if ratings.is_empty():
		return null

	var returned_rating: Rating = ratings[0]
	for rating: Rating in ratings:
		if difference <= rating.timing:
			returned_rating = rating
		else:
			break

	return returned_rating
