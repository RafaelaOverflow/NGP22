extends RefCounted
class_name POP

const growth_rate = 0.001

enum JOB {
	UNEMPLOYED,
	HUNTER_GATHERER
}

var job : JOB = 0

var size : int = 1
var grow_progress : float = 0

func _init(_size=1,job=0) -> void:
	size = _size

func update(t,planet,data:PlanetData,tile:PlanetTile,tp,pc):
	if pc > tp:
		grow_progress += float(size*t)*growth_rate
	else:
		if !tile.has_tech(&"agriculture") or !tile.has_tech(&"writing"):
			tile.tech_points += 0.000001*float(size*t)
		elif tile.polity == null:
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
			
		var m = float(tp)/float(pc)
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
			if n.get_total_pop() < x:
				n.pops.append(POP.new(x))
				size -= x

func try_merge(other:POP):
	if true:
		other.size += size
		other.grow_progress += grow_progress
		return true
	return false

func take(amount : int = 1):
	if size > amount:
		pass

func get_save_data() -> Dictionary:
	var s = {}
	s.job = job
	s.size = size
	s.grow_progress = grow_progress
	return s

static func from_save_data(s : Dictionary) -> POP:
	var p = POP.new()
	p.size = s.size
	p.job = s.job
	p.grow_progress = s.grow_progress
	return p
