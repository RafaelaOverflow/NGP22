extends CelestialBody
class_name Planet

@export var show_planet : bool = false
@export var rotate_speed : float = 6.37045
@export var orbit_around : Node3D
@onready var camera_holder: Node3D = $CameraHolder

@export var data : PlanetData = null
@onready var faces = [$PlanetFace, $PlanetFace2, $PlanetFace3, $PlanetFace4, $PlanetFace5, $PlanetFace6]
@onready var atmosphere: MeshInstance3D = $Atmosphere
var threads : Array[ContinuousThread] = []

@export var sync_data : Dictionary = {}

var cd = 0
var orbit_time = 0
var p = 0

var pid = 0

func _ready() -> void:
	var s = data.radius/5000.0
	scale = Vector3(s,s,s)
	if !show_planet:
		position.x = cd
		if pt.yd == 0:
			pt.yd = int(position.x/74)
		orbit_time = float(pt.yd)
		if Global.is_host:
			sync_data = get_save_data()
		else:
			pass
			#sync(sync_data)
		super()
		add_to_group("planet")
		for face in faces:
			face.regenerate_mesh(data)
		threads.append(ContinuousThread.new(update))
		threads.append(ContinuousThread.new(update_tex))
		
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
	atmosphere.set_instance_shader_parameter("a",data.atmosphere)

func _physics_process(delta: float) -> void:
	for thread in threads:
		if thread != null and thread.finished:
			threads.erase(thread)
	rotate_y(rotate_speed*delta*Global.time_scale)
	if Global.rotate_with_planet: camera_holder.rotate_y(-rotate_speed*delta*Global.time_scale)
	p = fposmod((delta/orbit_time)*Global.time_scale+p,1.0)
	global_position = Vector3(cd * sin(p*PI*2),0,cd * cos(p*PI*2)) + orbit_around.global_position
	atmosphere.visible = Global.atmosphere_visible
	#sync_data = get_save_data()



var pt : PlanetTime = PlanetTime.new()
var tex_update = false
var last_map_mode = 0
var last_t = 0
func update():
	if Global.is_host:
		var nt = Global.t
		if nt != last_t:
			var t
			if nt > last_t:
				t = nt - last_t
			else:
				t = nt + (Global.t_limit - last_t)
			pt.add(t)
			last_t = nt
			data.update(t,self)
			tex_update = true
			sync_data = get_save_data()
	else:
		sync(Global.client.sync.p[pid])
		data.sync_update(self)
		tex_update = true

func update_tex():
	if Global.map_mode != last_map_mode or tex_update:
		var tex_update = false
		last_map_mode = Global.map_mode
		for face in faces:
			face.update_material(data)

func get_save_data(sync=false) -> Dictionary:
	var s = {}
	s.pt = pt.get_save_data()
	s.data = data.get_save_data(sync)
	s.p = p
	s.pid = pid
	s.cd = cd
	return s

func sync(s:Dictionary):
	pt = PlanetTime.from_save_data(s.pt)
	data.sync(s.data,self)
	p = s.p
	pid = s.pid
	cd = s.cd

static func from_save_data(s) -> Planet:
	var pl = preload("res://planet/Planet.tscn").instantiate()
	pl.pt = PlanetTime.from_save_data(s.pt)
	pl.data = PlanetData.from_save_data(s.data,pl)
	pl.p = s.p
	pl.pid = s.pid
	pl.cd = s.cd
	return pl
