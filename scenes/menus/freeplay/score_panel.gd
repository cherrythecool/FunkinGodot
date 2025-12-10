extends Panel


@onready var score_label: Label = $score_label
@onready var misses_label: Label = $misses_label
@onready var accuracy_label: Label = $accuracy_label
@onready var rank_label: Label = $rank_label


func refresh(data: Dictionary) -> void:
	score_label.text = 'Score: %s' % data.get('score', 'N/A')
	misses_label.text = 'Misses: %s' % data.get('misses', 'N/A')
	rank_label.text = 'Rank: %s' % data.get('rank', 'N/A')

	if data.has('accuracy') and data.get('accuracy') is not String:
		accuracy_label.text = 'Accuracy: %.3f%%' % [GameUtils.truncate_float_to(data.get('accuracy'), 3)]
	else:
		accuracy_label.text = 'Accuracy: N/A'
