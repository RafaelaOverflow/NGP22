extends Resource
class_name BuildingType

@export var cost : float = 100.0
@export var land_use : float = 1.0
@export var id : StringName

@export var limits : Array[Limit] = []
@export var requirements : Array[Requirement] = []
@export var modifiers : Array[Modifier] = []
@export var hire : Dictionary[POP.JOB,int] = {}
@export var consume : Dictionary[StringName,float] = {}
@export var produce : Dictionary[StringName,float] = {}

func get_limit(tile:PlanetTile):
	#if !is_available(tile): return 0
	var available_area = tile.get_available_land()
	var l = int(available_area/land_use)
	for limit in limits:
		match limit.type:
			Limit.FLAT:
				l = min(l,limit.l-tile.get_building_size(id))
			Limit.AREA_PROPORTION:
				match limit.area:
					AreaLimit.AREA.ALL:
						l = min(l,int((tile.get_data().area_per_tile*limit.proportion)/land_use)-(tile.get_building_size(id)))
					AreaLimit.AREA.HUMID:
						l = min(l,int((tile.get_data().area_per_tile*tile.humidity*limit.proportion)/land_use)-(tile.get_building_size(id)))
			Limit.POP_:
				l = min(l,(tile.get_total_pop()/limit.p)-tile.get_building_size(id))
	
	return max(l,0)

func is_available(tile:PlanetTile):
	for r in requirements:
		match r.type:
			Requirement.TECH:
				if !tile.has_tech(r.tech): return false
	return true
