extends RefCounted
class_name PlanetTile

var planet_ref : WeakRef
func get_planet() -> Planet:
	return planet_ref.get_ref()
var data_ref : WeakRef
func get_data() -> PlanetData:
	return data_ref.get_ref()

const POPULATION_CAPACITY_ADD = &"AddPopCap"
const RESEARCH_ADD = &"AddTech"
const LAND_USE = &"LandUse"
const BUILD_POINTS_ADD = &"BuildAdd"

var height : float
func get_altitude(data : PlanetData = get_data()):
	return (height-data.ocean_level)*8000
var humidity : float
func get_humidity(data := get_data()):
	if is_ocean(data): return 100.0
	return humidity*100.0
var cold : float
func get_temperature(planet : Planet  = get_planet()):
	return lerp(40,-10,(cold))
var forest : float
func get_forestation(data = get_data()):
	return forest*100.0
var pos : Vector3
var id : Vector3i
var pops : Array[POP] = []
var polity = null
func get_polity() -> Polity:
	return Global.polities.get(polity)
func change_polity(new_polity:Polity):
	if polity != null: polity.remove_tile(self)
	new_polity.add_tile(self)
var techs : Dictionary[StringName,float] = {}
func has_tech(id : StringName):
	return techs.get(id,0.0) >= 1
func add_tech_progress(tid,p:float):
	if !techs.has(tid): techs[tid] = 0.0
	var tech = Global.techs.get(tid)
	var x = min((1.0-techs[tid])*tech.cost,p)
	techs[tid] = min(techs[tid]+(p/tech.cost),1.0)
	return x
var tech_points : float = 0
var buildings : Dictionary[StringName,Building]
func get_building_size(type:StringName):
	if !buildings.has(type): return 0
	return buildings[type].size
func add_building(type:StringName, amount : int = 1) -> void:
	if !buildings.has(type): buildings[type] = Building.new(type,amount)
	else: buildings[type].size += amount
func expand_building(type:StringName, amount : float = 0.0) -> void:
	if !buildings.has(type): buildings[type] = Building.new(type,0)
	buildings[type].expand_progress += amount / Global.building_types[type].cost
	if buildings[type].expand_progress > 1.0:
		var i = int(buildings[type].expand_progress)
		buildings[type].size += i
		buildings[type].expand_progress -= float(i)
func get_available_building(data:PlanetData = get_data()):
	var blist = []
	for b in Global.building_types.values():
		if b.is_available(self): blist.append(b.id)
	return blist
var build_points = 0.0
var modifiers := {}
func get_modifier(mid,default = 0):
	return modifiers.get(mid,default)
func modify(key,value):
	if !modifiers.has(key): modifiers[key] = value
	else: modifiers[key] += value
func update_modifiers():
	modifiers = {}
	for b : Building in buildings.values():
		b.modify(self)
	for t : StringName in techs.keys():
		if has_tech(t):
			var tech = Global.techs[t]
			tech.modify(self)
func get_available_land(data:PlanetData = get_data()) -> float:
	return data.area_per_tile - get_modifier(LAND_USE)

func _init() -> void:
	pass

func first_pass(_id,sphere_pos,planet_pos:Vector3,data:PlanetData) -> PlanetTile:
	height = Global.gen_temp.noise0.get_noise_3dv(planet_pos*0.01)
	humidity = Global.gen_temp.noise1.get_noise_3dv(planet_pos*0.02)
	humidity = humidity*(2.0-abs(humidity))
	humidity = Util.simplify_range(humidity,-1.0,1.0)
	
	cold = abs((planet_pos).normalized().y)
	id = _id
	return self

func second_pass(data):
	if height > data.ocean_level:
		#forest = data.atmosphere
		pass

func _normal_color(data = get_data()) -> Color:
	var color : Color
	if is_ocean(data):
		color = Global.color_ramps.ocean.sample(Util.simplify_range(height,0,data.ocean_level))
	else:
		color = Global.color_ramps.surfaceh.sample(humidity)
		color = color.lerp(Global.color_ramps.green.sample(Util.simplify_range(height,data.ocean_level,1)),forest)
	if data.ocean_level > 0.1 or data.atmosphere > 0.1: color = color.lerp(Color.WHITE,smoothstep(0.8,1,cold))
	return color

func get_color(data:PlanetData = get_data()) -> Color:
	match Global.map_mode:
		0:
			return _normal_color(data)
		1:
			return Color(height,height,height)
		2:
			return Color.ORANGE_RED.lerp(Color.BLUE,cold)
		3:
			var p = float(get_total_pop())/float(data.max_pop)
			if p == 0: return Color.BLACK
			p = p*0.9+0.1
			return Color(p,p,p)
		4:
			return Color(float(id.x)/float(data.texture_resolution-1),float(id.y)/float(data.texture_resolution-1),float(id.z)/6.0)
		5:
			return Color(0,forest,0)
		6:
			if is_ocean(data): return Color(0,0,1)
			return Color(0,0,humidity)
		7:
			if polity == null: return _normal_color(data)
			return get_polity().color
		8:
			if !Global.map_detail is StringName: return _normal_color(data)
			var c = techs.get(Global.map_detail,0.0)
			return Color(c,c,c)
		9:
			var l = get_modifier(LAND_USE)/data.area_per_tile
			if l == 0: return _normal_color(data)
			return Color(l,l,l)
	return Color.WHITE

func get_neighbours_pos(data:PlanetData = get_data()) -> Array[Vector3i]:
	var n :Array[Vector3i]= []
	var l = data.texture_resolution-1
	if id.x == 0:
		match id.z:
			0:
				n.append(Vector3i(id.y,0,5))
			1:
				n.append(Vector3i(l-id.y,l,4))
			2:
				n.append(Vector3i(id.y,0,1))
			3:
				n.append(Vector3i(l-id.y,l,0))
			4:
				n.append(Vector3i(id.y,0,3))
			5:
				n.append(Vector3i(l-id.y,l,2))
	else:
		n.append(Vector3i(id.x-1,id.y,id.z))
	if id.x == l:
		match id.z:
			0:
				n.append(Vector3i(l-id.y,0,4))
			1:
				n.append(Vector3i(id.y,l,5))
			2:
				n.append(Vector3i(l-id.y,0,0))
			3:
				n.append(Vector3i(id.y,l,1))
			4:
				n.append(Vector3i(l-id.y,0,2))
			5:
				n.append(Vector3i(id.y,l,3))
	else:
		n.append(Vector3i(id.x+1,id.y,id.z))
	if id.y == 0:
		match id.z:
			0:
				n.append(Vector3i(l,l-id.x,2))
			1:
				n.append(Vector3i(0,id.x,2))
			2:
				n.append(Vector3i(l,l-id.x,4))
			3:
				n.append(Vector3i(0,id.x,4))
			4:
				n.append(Vector3i(l,l-id.x,0))
			5:
				n.append(Vector3i(0,id.x,0))
	else:
		n.append(Vector3i(id.x,id.y-1,id.z))
	if id.y == l:
		match id.z:
			0:
				n.append(Vector3i(0,l-id.x,3))
			1:
				n.append(Vector3i(l,id.x,3))
			2:
				n.append(Vector3i(0,l-id.x,5))
			3:
				n.append(Vector3i(l,id.x,5))
			4:
				n.append(Vector3i(0,l-id.x,1))
			5:
				n.append(Vector3i(l,id.x,1))
	else:
		n.append(Vector3i(id.x,id.y+1,id.z))
	return n

func get_neighbours(data:PlanetData = get_data()) -> Array[PlanetTile]:
	var a : Array[PlanetTile] = []
	for np in get_neighbours_pos(data):
		a.append(data.tiles.get(np))
	return a

func get_total_pop() -> int:
	var i = 0
	for pop in pops:
		i+=pop.size
	return i
func has_pop() -> bool:
	return pops.size() > 0

func get_pop_capacity(data : PlanetData = get_data()) -> int:
	var c = 100 + get_modifier(POPULATION_CAPACITY_ADD) + int(data.area_per_tile*forest*0.01)
	return c

func get_forest_limit(planet := get_planet(),data := get_data()):
	return min(humidity,1.0-(get_modifier(LAND_USE)/data.area_per_tile))

func update(t,planet : Planet = get_planet(),data : PlanetData = get_data()):
	update_modifiers()
	var fl = get_forest_limit(planet,data)
	if forest != 0:
		if forest < fl:
			forest = min(fl,forest+float(t)*forest*0.01)
		elif forest > fl:
			forest = fl
		for n in get_neighbours(data):
			var nfl = n.get_forest_limit(planet,data)
			if n.forest < nfl and !n.is_ocean(data):
				n.forest = min(nfl,n.forest+float(t)*forest*0.001)
	var tp = get_total_pop()
	var pc = get_pop_capacity(data)
	if tp > data.nmax_pop: data.nmax_pop = tp
	data.npop += tp
	for pop in pops:
		pop.update(t,planet,data,self,tp,pc)
	if pops.size()>1:
		for pop in pops:
			for pop2 in pops:
				if pop != pop2:
					if pop.try_merge(pop2):
						pops.erase(pop)
						return
	tech_points += get_modifier(RESEARCH_ADD)*float(t)
	if tech_points > 0:
		var spread_points = tech_points * 10.0
		for tech : Tech in Global.techs.values():
			if !has_tech(tech.id):
				if tech.is_available(self):
					tech_points -= add_tech_progress(tech.id,tech_points)
					if has_tech(tech.id):
						for e : Event in tech.on_discovery:
							match e.type:
								Event.ADD_BUILDING:
									add_building(e.building_type)
				if tech_points <= 0: break
		for n in get_neighbours(data):
			if n.has_pop():
				for techid in techs.keys():
					var tech = Global.techs[techid]
					if has_tech(techid) and !n.has_tech(techid) and Global.techs[techid].is_available(n):
						add_tech_progress(techid,spread_points)
						if n.has_tech(techid):
							for e : Event in tech.on_discovery:
								match e.type:
									Event.ADD_BUILDING:
										n.add_building(e.building_type)
	build_points += float(t)*get_modifier(BUILD_POINTS_ADD)
	if polity != null:
		var p = get_polity()
		if self == p.capital:
			p.update(t,planet,data,self)
	else:
		if build_points > 0.0:
			pass


func is_ocean(data:PlanetData = get_data()):
	return height < data.ocean_level

func get_save_data() -> Dictionary:
	var s = {}
	s.height = height
	s.humidity = humidity
	s.cold = cold
	s.forest = forest
	s.pos = pos
	s.id = id
	s.pops = []
	for pop : POP in pops:
		s.pops.append(pop.get_save_data())
	s.polity = polity
	s.tech_points = tech_points
	s.build_points = build_points
	s.buildings = []
	for b : Building in buildings.values():
		s.buildings.append(b.get_save_data())
	s.techs = techs
	return s

static func from_save_data(s, planet : Planet, data : PlanetData) -> PlanetTile:
	var t = PlanetTile.new()
	t.planet_ref = weakref(planet)
	t.data_ref = weakref(data)
	t.id = s.id
	t.height = s.height
	t.humidity = s.humidity
	t.cold = s.cold
	t.forest = s.forest
	t.pos = s.pos
	for pop in s.pops:
		t.pops.append(POP.from_save_data(pop))
	t.polity = s.polity
	t.tech_points = s.tech_points
	t.build_points = s.build_points
	for b in s.buildings:
		t.buildings[b.type] = Building.from_save_data(b)
	t.techs = s.techs
	t.update_modifiers()
	return t
