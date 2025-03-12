extends RefCounted
class_name Building
var type : StringName
var size : int = 1
var expand_progress : float = 0.0

func _init(_type : StringName, _size : int = 1) -> void:
	type = _type
	size = _size

func modify(tile:PlanetTile) -> void:
	if size == 0: return
	var bt = Global.building_types[type]
	if bt.land_use > 0.0:
		tile.modify(PlanetTile.LAND_USE,bt.land_use*float(size)) 
	for m : Modifier in bt.modifiers:
		tile.modify(m.target,m.scaled(size))

func get_save_data() -> Dictionary:
	var s = {}
	s.type = type
	s.size = size
	s.expand_progress = expand_progress
	return s

static func from_save_data(s) -> Building:
	var b = Building.new(s.type,s.size)
	b.expand_progress = s.expand_progress
	return b
