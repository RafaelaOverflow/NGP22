extends Requirement
class_name TileTraitRequirement

enum TRAIT {
	IS_CAPITAL
}

@export var t : TRAIT

func _init() -> void:
	type = TILE_TRAIT
