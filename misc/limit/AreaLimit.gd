extends Limit
class_name AreaLimit

enum AREA {
	ALL,
	HUMID,
}
@export var area : AREA
@export var proportion : float = 0.5
func _init() -> void:
	type = AREA_PROPORTION
