extends RefCounted
class_name Polity

var id : int = 0
var color : Color
var capital : PlanetTile
var territories : Array[PlanetTile] = []
var laws : Dictionary[StringName,StringName] = {&"core" : &"informal_gov",&"power":&"informal_admin"}
func set_law(law_id:StringName) -> void:
	var law = Global.laws[law_id]
	if laws[law.category] == law_id: return
	Event.tile_events(law.on_set,capital)
	laws[law.category] = law_id
	update_gov_type()
var gov_type : StringName = &"default"
func update_gov_type() -> void:
	var g = &"default"
	var m = 0
	for gov : GovernmentType in Global.gov_types:
		var p = 0
		for r in gov.requirements.keys():
			if Requirement._polity_check(r,self): p+=gov.requirements[r]
		if p > m:
			m = p
			g = gov.id
	gov_type = g

func _init(tile:PlanetTile) -> void:
	if tile == null: return
	while true:
		var i = randi()
		if !Global.polities.has(i):
			Global.polities[i] = self
			id = i
			break
	color = Color(randf(),randf(),randf()*0.2)
	capital = tile
	territories.append(capital)

func get_name() -> String:
	return "%s" % id

func remove_tile(tile:PlanetTile) -> void:
	tile.polity = null
	territories.erase(tile)
	if capital == tile:
		if territories.size() == 0:
			Global.polities.erase(id)
		capital = territories[0]

func add_tile(tile:PlanetTile) -> void:
	territories.append(tile)
	tile.polity = id

func get_pop() -> int:
	var pop = 0
	for t in territories:
		pop += t.get_total_pop()
	return pop

func update(t,planet:Planet,data:PlanetData,tile:PlanetTile):
	var bp = 0.0
	var lbp = 0.0
	var pop = 0
	var avbuild = []
	var avbuildt = []
	var tpop2 = []
	var pop2 = 0
	for te in territories:
		pop += te.get_total_pop()
		bp += te.build_points
		te.build_points = 0.0
		var a = te.get_available_building(data)
		if a.size() > 0:
			var tpop = te.get_total_pop()
			pop2 += tpop
			tpop2.append(tpop)
			avbuild.append(a)
			avbuildt.append(te)
	if pop2 > 0:
		for i in avbuild.size():
			var b : BuildingType = Global.building_types[avbuild[i].pick_random()]
			var te : PlanetTile = avbuildt[i]
			var avbp = bp*(float(tpop2[i])/float(pop2))
			var l = b.get_limit(te)
			te.expand_building(b.id,max(min(avbp,b.cost*float(l)),0))
	


func get_save_data() -> Dictionary:
	var s = {}
	s.id = id
	s.color = color
	s.capital = Util.vec3w(capital.id,capital.get_planet().pid)
	s.laws = laws
	s.territories = []
	for tile in territories:
		s.territories.append(tile.get_global_id())
	return s

func sync(s):
	color = s.color
	capital = Global.get_tile(s.capital)
	laws = s.laws
	var nt : Array[PlanetTile] = []
	for tile in s.territories:
		nt.append(Global.get_tile(tile))
	territories = nt
	update_gov_type()

static func from_save_data(s) -> Polity:
	var p = Polity.new(null)
	p.id = s.id
	p.color = s.color
	p.capital = Global.get_tile(s.capital)
	p.laws = s.laws
	for tile in s.territories:
		p.territories.append(Global.get_tile(tile))
	p.update_gov_type()
	return p

class Name:
	extends RefCounted
	var base
