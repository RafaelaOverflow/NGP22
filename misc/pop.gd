extends RefCounted
class_name POP

const REMOVE_HUNTER_GATHERER = &"RemoveHG"
const growth_rate = 0.001

enum JOB {
	HUNTER_GATHERER,
	UNEMPLOYED,
	LABORER,
	PEASANT,
	ENGINEER,
	FARMER,
	SCHOLAR,
	CLERK,
	ARISTOCRAT,
	OFFICER,
	SERVICEMEN,
	CAPITALIST,
	CLERGY,
	BUREAUCRAT,
	POLITICIAN
}

var job : JOB = 0
var building = null

var size : int = 1
var grow_progress : float = 0

func _init(_size=1,job=0) -> void:
	size = _size

func update(t,planet,data:PlanetData,tile:PlanetTile,tp,pc):
	if size <= 0:
		if building != null:
			tile.buildings[building].pops.erase(self)
		tile.pops.erase(self)
		return
	var m = (float(size)/float(tp))
	if pc > tp:
		grow_progress += min(float(size*t)*growth_rate,-m*float(tp-pc))
	else:
		if tile.polity == null and tile.has_tech(&"agriculture") and tile.has_tech(&"writing"):
			var np = null
			for n in tile.get_neighbours(data):
				if n.polity != null:
					if np == null:
						np = n.get_polity()
						continue
					var p = n.get_polity()
					if p.territories.size() < np.territories.size(): np = p
			if np != null:
				np.add_tile(tile)
			elif t > randi_range(0,t+99):
				tile.polity = Polity.new(tile).id
		grow_progress = -m*float(tp-pc)
		#grow_progress = max(-m*float(pc),grow_progress+float(tp*t)*(growth_rate*(2.0*m+(-m*m))))
	if abs(grow_progress) > 1.0:
		var x = int(grow_progress)
		grow_progress -= float(x)
		size += x
	if tp > 100:
		var ns = tile.get_neighbours(data)
		for n in ns:
			if n.is_ocean(data): continue
			var x = size/10
			if n.get_total_pop() < min(x,n.get_pop_capacity()):
				var npop = POP.new(x)
				if job == JOB.UNEMPLOYED: npop.job = JOB.UNEMPLOYED
				n.pops.append(npop)
				size -= x
	if job == JOB.HUNTER_GATHERER:
		tile.tech_points += 0.000001*float(size*t)
		var x = tile.get_modifier(REMOVE_HUNTER_GATHERER)
		if x > 0:
			unemploy(x*t,tile)
	if size <= 0:
		if building != null:
			tile.buildings[building].pops.erase(self)
		tile.pops.erase(self)
		return

func try_merge(other:POP):
	if job == other.job and building == other.building:
		other.size += size
		other.grow_progress += grow_progress
		return true
	return false

func take(amount : int = 1):
	if size > amount:
		pass

func unemploy(amount : int, tile : PlanetTile):
	amount = min(amount,size)
	if size > amount:
		size -= amount
		var npop = POP.new(amount)
		npop.job = JOB.UNEMPLOYED
		tile.pops.append(npop)
		return 0
	else:
		if job != JOB.HUNTER_GATHERER:
			tile.buildings[building].pops.erase(self)
			building = null
		job = JOB.UNEMPLOYED
		return amount - size

func employ(amount : int, tile : PlanetTile,j,b: Building):
	amount = min(amount,size)
	if size > amount:
		size -= amount
		var npop = POP.new(amount)
		npop.job = j
		npop.building = b.type
		b.pops.append(npop)
		tile.pops.append(npop)
		return 0
	else:
		job = j
		b.pops.append(self)
		building = b.type
		return size-amount

func get_save_data() -> Dictionary:
	var s = {}
	s.job = job
	s.size = size
	s.grow_progress = grow_progress
	s.building = building
	return s

static func from_save_data(s : Dictionary,tile:PlanetTile) -> POP:
	var p = POP.new()
	p.size = s.size
	p.job = s.job
	p.grow_progress = s.grow_progress
	p.building = s.building
	if p.building != null:
		if tile.buildings.has(p.building):
			tile.buildings[p.building].pops.append(p)
		else:
			p.building = null
	return p
