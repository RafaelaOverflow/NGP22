extends Event
class_name AddBuildingEvent
@export var building_type : StringName
func _init() -> void:
	type = ADD_BUILDING
