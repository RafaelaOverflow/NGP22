extends Resource
class_name PlanetData

const normal_map = [Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,1,0),Vector3(0,-1,0),Vector3(0,0,1),Vector3(0,0,-1)]
func get_side(normal):
	return normal_map.find(normal)

@export var radius = 5000.0
@export var mesh_resolution = 8
@export var texture_resolution = 8
@export var ocean_level = 0.0
@export var atmosphere = 1.0
var area = 0.0
var tiles : Dictionary[Vector3i,PlanetTile] = {}
var regions : Array[PlanetRegion] = []
var area_per_tile = 1
var generating_tiles = false
var max_pop = 1
var nmax_pop = 1
var pop = 0
var npop = 0
var max_produce : Dictionary[StringName,float] = {}
var nmax_produce : Dictionary[StringName,float] = {}
var max_consume : Dictionary[StringName,float] = {}
var nmax_consume : Dictionary[StringName,float] = {}


func gen_tiles(planet:Planet):
	var wp = weakref(planet)
	var wd = weakref(self)
	generating_tiles = true
	area = (4*PI*radius*radius)#*5.0
	area_per_tile = (area/(texture_resolution*texture_resolution*6))
	tiles = {}
	for normal in normal_map:
		var axisA := Vector3(normal.y, normal.z, normal.x)
		var axisB : Vector3 = normal.cross(axisA)
		for y in texture_resolution:
			for x in texture_resolution:
				var percent : Vector2 = Vector2(x,y) / (texture_resolution-1)
				var cube_pos : Vector3 = normal + (percent.x-0.5) * 2.0 * axisA + (percent.y-0.5) * 2.0 * axisB
				var sphere_pos : Vector3 = cube_pos.normalized()
				var planet_pos : Vector3 =  sphere_pos * radius
				tiles[Vector3i(x,y,get_side(normal))] = PlanetTile.new().first_pass(Vector3i(x,y,get_side(normal)),sphere_pos,planet_pos,self)
	var max_height = tiles[Vector3i.ZERO].height
	var min_height = tiles[Vector3i.ZERO].height
	var hvalue = 0.0
	var tile_count = texture_resolution*texture_resolution*6
	for tile : PlanetTile in tiles.values():
		if tile.height > max_height: max_height = tile.height
		if tile.height < min_height: min_height = tile.height
		hvalue += tile.humidity
	hvalue = hvalue/float(tile_count)
	ocean_level = hvalue
	for tile : PlanetTile in tiles.values():
		tile.height = Util.simplify_range(tile.height,min_height,max_height)
		tile.second_pass(self)
		tile.planet_ref = wp
		tile.data_ref = wd
	#tiles[Vector3i.ZERO].pops.append(POP.new(100))
	generating_tiles = false
	for good in Global.goods.keys():
		max_consume[good] = 0
		max_produce[good] = 0
	gen_regions()

func gen_regions():
	regions = []
	var unregioned = tiles.keys()
	var i = 0
	while true:
		var r = PlanetRegion.new()
		regions.append(r)
		var t = tiles[unregioned[0]]
		r.is_ocean = t.is_ocean(self)
		gen_region(i,r,t,unregioned)
		if unregioned.size() == 0:
			break
		i+=1

func gen_region(i:int,region : PlanetRegion, tile : PlanetTile, unregioned : Array):
	unregioned.erase(tile.id)
	tile.region = i
	region.tiles.append(tile)
	var b = false
	for n in tile.get_neighbours(self):
		if n.is_ocean(self) == region.is_ocean:
			if n.id in unregioned:
				gen_region(i,region,n,unregioned)
		else: b = true
	if b: region.border_tiles.append(tile)

func update(t,planet):
	nmax_pop = 1
	npop = 0
	for r in regions:
		r.npop = 0
	for good in Global.goods.keys():
		nmax_consume[good] = 0
		nmax_produce[good] = 0
	for tile : PlanetTile in tiles.values():
		tile.update(t,planet,self)
	max_pop = nmax_pop
	pop = npop
	max_consume = nmax_consume
	max_produce = nmax_produce
	for r in regions:
		r.pop = r.npop

func sync_update(planet):
	nmax_pop = 1
	npop = 0
	for r in regions:
		r.npop = 0
	for good in Global.goods.keys():
		nmax_consume[good] = 0
		nmax_produce[good] = 0
	for tile : PlanetTile in tiles.values():
		tile.sync_update(planet,self)
	max_pop = nmax_pop
	pop = npop
	max_consume = nmax_consume
	max_produce = nmax_produce
	for r in regions:
		r.pop = r.npop

func get_texture(normal) -> ImageTexture:
	var img = Image.create(texture_resolution,texture_resolution,false,Image.FORMAT_RGB8)
	var axisA := Vector3(normal.y, normal.z, normal.x)
	var axisB : Vector3 = normal.cross(axisA)
	for y in texture_resolution:
		for x in texture_resolution:
			img.set_pixel(x,y,tiles.get(Vector3i(x,y,get_side(normal))).get_color(self))
	return ImageTexture.create_from_image(img)

func get_material(normal) -> Material:
	var tex = get_texture(normal)
	var mat : ShaderMaterial = Global.base_planet_mat.duplicate()
	mat.set_shader_parameter("tex",tex)
	return mat

func get_save_data(sync=false) -> Dictionary:
	var s = {}
	s.radius = radius
	s.mesh_resolution = mesh_resolution
	s.texture_resolution = texture_resolution
	s.ocean_level = ocean_level
	s.atmosphere = atmosphere
	s.tiles = []
	for tile : PlanetTile in tiles.values():
		s.tiles.append(tile.get_save_data(sync))
	return s

static func from_save_data(s, planet : Planet) -> PlanetData:
	var d = PlanetData.new()
	d.radius = s.radius
	d.mesh_resolution = s.mesh_resolution
	d.texture_resolution = s.texture_resolution
	d.area = (4*PI*d.radius*d.radius)#*5.0
	d.area_per_tile = (d.area/(d.texture_resolution*d.texture_resolution*6))
	d.ocean_level = s.ocean_level
	d.atmosphere = s.atmosphere
	for good in Global.goods.keys():
		d.nmax_consume[good] = 0
		d.nmax_produce[good] = 0
	for tile in s.tiles:
		d.tiles[tile.id] = PlanetTile.from_save_data(tile,planet,d)
	d.gen_regions()
	return d

func sync(s,planet:Planet):
	ocean_level = s.ocean_level
	atmosphere = s.atmosphere
	for tile in s.tiles:
		tiles[tile.id].sync(tile)
