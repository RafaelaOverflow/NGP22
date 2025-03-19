extends Requirement
class_name NotRequirement
@export var requirements : Array[Requirement]
func _init() -> void:
	type = NOT
