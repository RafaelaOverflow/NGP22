extends Event
class_name ConditionalEvent
@export var success : Array[Event]
@export var fail : Array[Event]
@export var requirements : Array[Requirement]
func _init() -> void:
	type = CONDITIONAL
