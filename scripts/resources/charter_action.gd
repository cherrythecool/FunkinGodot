extends Resource
class_name CharterAction

enum ActionType {
	Place,
	Remove
}

var type: ActionType = ActionType.Place
var data: Dictionary = {}
