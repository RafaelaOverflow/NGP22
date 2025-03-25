extends RefCounted
class_name Building
var type : StringName
var size : int = 1
var expand_progress : float = 0.0
var pops : Array[POP] = []

func get_hiring_limits() -> Dictionary[POP.JOB,int]:
	var bt = Global.building_types[type]
	var ls : Dictionary[POP.JOB,int] = {}
	for key in bt.hire.keys():
		ls[key] = bt.hire[key]*size
	return ls

func get_total_hiring_limit() -> int:
	var bt = Global.building_types[type]
	var i = 0
	for h in bt.hire.values():
		i+= h * size
	return i

func get_hired_amount_per_job():
	var d : Dictionary[POP.JOB,int] = {}
	for pop in pops:
		if !d.has(pop.job): d[pop.job] = pop.size
		else: d[pop.job] += pop.size
	return d

func get_total_hired():
	var i = 0
	for pop in pops:
		i += pop.size
	return i

func get_available_space(job : POP.JOB) -> int:
	var ls = get_hiring_limits()
	var p = get_hired_amount_per_job()
	return ls.get(job,0)-p.get(job,0)

func get_available_spaces() -> Array[Array]:
	var a : Array[Array] = []
	var ls = get_hiring_limits()
	var p = get_hired_amount_per_job()
	for key in ls.keys():
		a.append([key,ls.get(key,0)-p.get(key,0)])
	return a

func _init(_type : StringName, _size : int = 1) -> void:
	type = _type
	size = _size

func update(t, tile:PlanetTile):
	var bt = Global.building_types[type]
	for s in get_available_spaces():
		var j = s[0]
		var v = s[1]
		if v > 0:
			for pop in tile.pops:
				if pop.job == POP.JOB.UNEMPLOYED or pop.job == POP.JOB.HUNTER_GATHERER:
					pop.employ(v,tile,j,self)
					break
		elif v < 0:
			var tu = -v # to unemploy
			while tu > 0:
				for pop in pops:
					if pop.job == j:
						tu = pop.unemploy(tu,tile)

func modify(tile:PlanetTile,modifiers:Dictionary) -> void:
	if size == 0: return
	var bt = Global.building_types[type]
	if bt.land_use > 0.0:
		Util.modify(modifiers,PlanetTile.LAND_USE,bt.land_use*float(size)) 
	for m : Modifier in bt.modifiers:
		Util.modify(modifiers,m.target,m.scaled(size))

func goods(tile:PlanetTile,consume:Dictionary,produce:Dictionary) -> void:
	if size == 0: return
	var bt = Global.building_types[type]
	var h = float(get_total_hired()) / float(get_total_hiring_limit())
	for key in bt.consume:
		Util.modify(consume,key,bt.consume[key]*float(size)*h)
	for key in bt.produce:
		Util.modify(produce,key,bt.produce[key]*float(size)*h)

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

func sync(s) -> void:
	type = s.type
	size = s.size
	expand_progress = s.expand_progress
	pops.clear()
