extends Resource
class_name Event
enum {
	CONDITIONAL,
	MULTI,
	ADD_BUILDING,
	SET_LAW,
}
var type = -1

static func tile_events(events,tile:PlanetTile):
	for event in events: tile_event(event, tile)

static func tile_event(event,tile : PlanetTile):
	match event.type:
		CONDITIONAL:
			if Requirement.tile_check(event.requirements,tile): tile_events(event.success,tile)
			else: tile_events(event.fail,tile)
		MULTI:
			tile_events(event.events,tile)
		ADD_BUILDING:
			tile.add_building(event.building_type)
		SET_LAW:
			if tile.polity != null:
				tile.get_polity().set_law(event.law)
