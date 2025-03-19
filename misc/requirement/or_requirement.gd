extends Requirement
class_name OrRequirement

@export var requirements : Array[Requirement]
func _init() -> void:
	type = OR
