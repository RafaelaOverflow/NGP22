extends Resource
class_name Tech

@export var tech_tree_pos := Vector2.ZERO
@export var id : StringName
@export var cost : float = 1.0
@export var requirements : Array[Requirement] = []
@export var on_discovery : Array[Event] = []
@export var modifiers : Array[Modifier] = []

func is_available(tile:PlanetTile):
	for r in requirements:
		match r.type:
			Requirement.TECH:
				if !tile.has_tech(r.tech): return false
	return true

func modify(tile:PlanetTile) -> void:
	for m : Modifier in modifiers:
		tile.modify(m.target,m.mod)
