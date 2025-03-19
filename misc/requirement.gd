extends Resource
class_name Requirement

enum {
	AlWAYS,
	MULTI,
	OR,
	NOT,
	TECH,
	TILE_TRAIT,
	LAW
}
var type : int

static func _tile_check(requirement : Requirement, tile : PlanetTile):
	match requirement.type:
		AlWAYS:
			return requirement.value
		MULTI:
			return tile_check(requirement.requirements,tile)
		OR:
			for r in requirement.requirements:
				if _tile_check(r,tile): return true
			return false
		NOT:
			for r in requirement.requirements:
				if _tile_check(r,tile): return false
			return true
		TECH:
			return tile.has_tech(requirement.tech)
		TILE_TRAIT:
			match requirement.t:
				TileTraitRequirement.TRAIT.IS_CAPITAL:
					if tile.polity == null: return false
					return tile.get_polity().capital == tile
		LAW:
			if tile.polity == null: return false
			return requirement.law in tile.get_polity().laws.values()

static func tile_check(requirements : Array[Requirement], tile : PlanetTile):
	for r in requirements:
		if !_tile_check(r,tile): return false
	return true

static func _polity_check(requirement : Requirement,polity : Polity):
	match requirement.type:
		AlWAYS:
			return requirement.value
		MULTI:
			return polity_check(requirement.requirements,polity)
		OR:
			for r in requirement.requirements:
				if _polity_check(r,polity): return true
			return false
		NOT:
			for r in requirement.requirements:
				if _polity_check(r,polity): return false
			return true
		TECH:
			return polity.capital.has_tech(requirement.tech)
		TILE_TRAIT:
			pass
		LAW:
			return requirement.law in polity.laws.values()

static func polity_check(requirements : Array[Requirement], polity : Polity):
	for r in requirements:
		if !_polity_check(r,polity): return false
	return true
