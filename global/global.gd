extends Node

var server := GameServer.new()
var client := GameClient.new()
@onready var chat: Control = $Chat

var is_host = true

@export var base_planet_mat : Material

var task_threads : Array[TaskThread] = []

@export var color_ramps : Dictionary[StringName,Gradient] = {}

const G = 0.0001
const AU = 29919.574 #Astronomical unit
const GOLDILOCK = 0.38*AU
@export var time_scale = 0.01
var tree : SceneTree

var atmosphere_visible := true
var rotate_with_planet := false
@export var map_mode = 0
var map_detail = null
var t :int= 0
var t_progress :float= 0.0
var t_limit : int = 99999999
var polities : Dictionary[int,Polity] = {}
@export var system_region : SystemRegion
@export var techs : Dictionary[StringName,Tech] = {}
@export var building_types : Dictionary[StringName,BuildingType] = {}
@export var resource_types : Dictionary[StringName,ResourceType] = {}
@export var goods : Dictionary[StringName,Good] = {}
@export var laws : Dictionary[StringName,Law] = {}
@export var law_categories : Array[StringName] = []
@export var gov_types : Array[GovernmentType] = []


@export var base_noise : Dictionary[StringName,FastNoiseLite] = {}

@onready var polities_display: Control = $PolitiesDisplay
@onready var building_display: Control = $BuildingDisplay
@onready var tech_tree: Control = $TechTree
@onready var pop_display: Control = $PopDisplay
@onready var host_menu: PanelContainer = $HostMenu
@onready var join_menu: PanelContainer = $JoinMenu

@onready var science_detail: OptionButton = $HBoxContainer/ScienceDetail
@onready var good_detail: OptionButton = $HBoxContainer/GoodDetail
@onready var good_detail_2: OptionButton = $HBoxContainer/GoodDetail2
@onready var law_detail: OptionButton = $HBoxContainer/LawDetail

var localization := LocalizationData.new()
func localize(id,args = {}):
	return localization.localize(id,args)

var loc_files = []
func update_loc_files():
	loc_files = []
	for loc_file : String in DirAccess.get_files_at("res://localization/"):
		loc_files.append("res://localization/"+loc_file)
	#for mod in settings.enabled_mods:
		#var lf = get_mod_folder(mod)+"/localization/"
		#if DirAccess.dir_exists_absolute(lf):
			#for loc_file : String in DirAccess.get_files_at(lf):
				#loc_files.append(lf+loc_file)
var available_localizations = []
var available_localizations_locs = []
func load_localization():
	var id = settings.localization
	var loc_info = {}
	update_loc_files()
	for loc_file : String in loc_files:
		var f = FileAccess.get_file_as_string(loc_file)
		f = JSON.parse_string(f)
		if f is Dictionary:
			if !f.language_id in available_localizations:
				available_localizations.append(f.language_id)
				available_localizations_locs.append(f.language)
			if f.language_id == id:
				loc_info.merge(f.localization)
	localization = LocalizationData.new(id,loc_info)
	update_localization()

signal localization_update

@export var themes : Dictionary[StringName,Theme] = {}

const settings_path = "user://settings.txt"
var settings = {
	"localization" : "english",
	"theme" : &"default",
	"disable_light_time_scale" : 5.0
}

func _ready() -> void:
	tree = get_tree()
	for tech in techs.keys():
		science_detail.add_item(tech)
	for good in goods.keys():
		good_detail_2.add_item(good)
	for c in law_categories:
		law_detail.add_item(c)
	science_detail.selected = 0
	good_detail.selected = 0
	good_detail_2.selected = 0
	law_detail.selected = 0
	load_settings()
	load_localization()

func update_localization():
	var i = 0
	for key in techs.keys():
		science_detail.set_item_text(i,localize("tech.%s" % key))
		i+=1
	i = 0
	for key in goods.keys():
		good_detail_2.set_item_text(i,localize("good.%s" % key))
		i+=1
	i = 0
	for c in law_categories:
		law_detail.set_item_text(i,localize("law_category.%s" % c))
		i+=1
	good_detail.set_item_text(0,localize("map_mode.10_d0"))
	good_detail.set_item_text(1,localize("map_mode.10_d1"))
	good_detail.set_item_text(2,localize("map_mode.10_d2"))
	
	emit_signal("localization_update")

func save_settings():
	FileAccess.open(settings_path,FileAccess.WRITE).store_string(var_to_str(settings))

func load_settings():
	if FileAccess.file_exists(settings_path):
		var s = str_to_var(FileAccess.open(settings_path, FileAccess.READ).get_as_text())
		#s = keys_types_and_values_to_dict(s,true)
		if s is Dictionary:
			settings.merge(s,true)
			#for action : String in ["left","right","front","back","jump","interact","grab","run","main","secondary","reload","up_action","right_action","down_action","left_action","prev_action_group","next_action_group","character_screen","map","toggle_third_person","toggle_hud","quicksave","quickload"]:
				#if !settings.inputmap.has(action): settings.inputmap[action] = InputMap.action_get_events(action)
			#settings.autosave = int(settings.autosave)
	update_settings()

func update_settings():
	for child in get_children(false):
		if child is Control:
			child.theme = themes[settings.theme]
	#for action: String in settings.inputmap.keys():
		#InputMap.action_erase_events(action)
		#for event in settings.inputmap[action]:
			##print(event)
			#InputMap.action_add_event(action,event)
		##print(InputMap.action_get_events(action))
	#AudioServer.set_bus_mute(0,settings.master_audio_muted)
	#AudioServer.set_bus_volume_db(0,settings.master_volume)
	#AudioServer.set_bus_mute(1,settings.music_audio_muted)
	#AudioServer.set_bus_volume_db(1,settings.music_volume)
	#AudioServer.set_bus_mute(2,settings.sfx_audio_muted)
	#AudioServer.set_bus_volume_db(2,settings.sfx_volume)
	#DisplayServer.window_set_mode(Global.settings.fullscreen_mode)
	#emit_signal("setting_update")
	save_settings()

func modify_noise_range(n,min = 0,max = 1):
	return (((n/2.0)+1) * (max-min))+min

var buffer_s = []
var sync_buffer : PackedByteArray = []
@export var sync : Array

var lts = 0
var f = 0
func _process(delta: float) -> void:
	
	science_detail.visible = map_mode == 8
	good_detail.visible = map_mode == 10
	good_detail_2.visible = map_mode == 10
	law_detail.visible = map_mode == 11
	for ta in task_threads:
		if ta.finished:
			ta.actual_thread.wait_to_finish()
			ta.actual_thread = null
			task_threads.erase(ta)
	t_progress += delta*time_scale
	if t_progress > 1.0:
		var x = int(t_progress/1.0)
		t_progress -= float(x*1.0)
		t = posmod(t+x,t_limit)
	var cam = tree.get_first_node_in_group("camera")
	if cam.using_controller or true:
		var screen_size_factor = $Control.size.x / 500.0
		var cv = Input.get_vector("look_left","look_right","look_up","look_down")*screen_size_factor*(100.0+200.0*(Input.get_action_strength("mouse_add_speed_l")+Input.get_action_strength("mouse_add_speed_r")))*delta
		#print(cv)
		if cv != Vector2.ZERO:
			Input.warp_mouse(cv+$Control.get_global_mouse_position())
		if Input.is_action_just_pressed("control_click"):
			click()
	if is_host:
		server.update()
	else:
		client.update()
	if time_scale >= settings.disable_light_time_scale:
		_on_light_button_toggled(false)
	if Input.is_action_just_pressed("menu") and cam.camera_mode != 1:
		$MainMenu.show()
	
	f+=1

func click():
	var event = InputEventMouseButton.new()
	event.position = $Control.get_global_mouse_position()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await tree.process_frame
	event.pressed = false
	Input.parse_input_event(event)

func display_tile_info(tile : PlanetTile,planet):
	$TileInfoDisplay.display(tile,planet)

func display_planet(planet:Planet):
	$TileInfoDisplay.display(planet.data.tiles[Vector3i.ZERO],planet)
	$TileInfoDisplay/TabContainer.current_tab = 1

func hide_tile_info():
	$TileInfoDisplay.hide()


func get_planet(id) -> Planet:
	for p : Planet in tree.get_nodes_in_group("planet"):
		if p.pid == id: return p
	return null

func get_tile(vec4) -> PlanetTile:
	var p = get_planet(vec4.w)
	return p.data.tiles[Util.vec4i_xyz(vec4)]

func clean_solar_system():
	lts = time_scale
	time_scale = 0.0
	t = 0
	for t in Global.task_threads:
		if t is ContinuousThread:
			t.continuar = false
	while task_threads.size() > 0:
		await tree.process_frame
	for child in solar_system.get_children():
		if child is Planet:
			child.tex_thread = null
		solar_system.remove_child(child)
		child.propagate_call("queue_free")

var random : RandomNumberGenerator
var gen_temp = {}
@onready var system_creation_menu: PanelContainer = $SystemCreationMenu
@onready var solar_system: Node3D = $SolarSystem
func create_solar_system(info : Dictionary) -> void:
	clean_solar_system()
	random = RandomNumberGenerator.new()
	random.seed = info.get("seed",Time.get_ticks_usec())
	TaskThread.new(func():
		var star = preload("res://star/star.tscn").instantiate()
		star.scale = Vector3(139.268,139.268,139.268)
		solar_system.add_child.call_deferred(star)
		var x0 = 6530.0
		var x = 71222.4
		gen_temp.min_hab = 1
		for i in info.get("planet_amount",4):
			var nt = ["base","base","type2"]
			for n in nt.size():
				gen_temp["noise%s" % n] = base_noise[nt[n]].duplicate()
				gen_temp["noise%s" % n].seed = random.randi()
			gen_temp["rnoises"] = []
			for r in resource_types.values():
				var n = base_noise.base.duplicate()
				n.seed = random.randi()
				gen_temp.rnoises.append(n)
			var p : Planet = preload("res://planet/Planet.tscn").instantiate()
			var pd := PlanetData.new()
			if gen_temp.min_hab > 0:
				p.cd = system_region.get_sub_region_by_tag(&"habitable").get_random_position(random)
			else:
				p.cd = system_region.get_random_position(random)
			var sr = system_region.get_sub_region_from_pos(p.cd)
			pd.radius = random.randf_range(2000,8000)
			p.orbit_around = star
			p.data = pd
			p.pid = i
			pd.mesh_resolution = info.get("planet_mesh_resolution",8)
			pd.texture_resolution = info.get("planet_resolution",8)
			#pd.mesh_resolution = clamp(pd.texture_resolution,3,32)
			pd.ocean_level = 0.5
			pd.gen_tiles(p)
			if &"ring" in sr.tags:
				p.ring_data = [random.randf_range(1.2,2.0),random.randf_range(0.5,4.0),Color(random.randf(),random.randf(),random.randf())]
			solar_system.add_child.call_deferred(p)
			gen_temp.min_hab -= 1
			if info.moon_percent > 0 and random.randf() <= info.moon_percent:
				for n in nt.size():
					gen_temp["noise%s" % n] = base_noise[nt[n]].duplicate()
					gen_temp["noise%s" % n].seed = random.randi()
				gen_temp["rnoises"] = []
				for r in resource_types.values():
					var n = base_noise.base.duplicate()
					n.seed = random.randi()
					gen_temp.rnoises.append(n)
				var m : Planet = preload("res://planet/Planet.tscn").instantiate()
				var md := PlanetData.new()
				md.radius = random.randf_range(500,min(8000,pd.radius*0.5))
				m.cd = pd.radius/5000.0 + random.randf_range(70,80)
				m.orbit_around = p
				m.data = md
				m.pid = i
				md.mesh_resolution = info.get("planet_mesh_resolution",8)
				md.texture_resolution = info.get("planet_resolution",8)
				#pd.mesh_resolution = clamp(pd.texture_resolution,3,32)
				md.ocean_level = 0.5
				md.gen_tiles(m)
				solar_system.add_child.call_deferred(m)
		)

func quit():
	for ta in task_threads:
		if ta is ContinuousThread:
			ta.continuar = false
		ta.actual_thread.wait_to_finish()
		task_threads.erase(ta)
	tree.quit()

@onready var environment: WorldEnvironment = $WorldEnvironment

func _on_light_button_toggled(toggled_on: bool) -> void:
	$Light.visible = toggled_on
	environment.environment.ambient_light_energy = 0.05 if toggled_on else 1.0
	$HBoxContainer/LightButton.release_focus()

func _on_rotate_with_planet_button_toggled(toggled_on: bool) -> void:
	rotate_with_planet = !toggled_on


func _on_atmosphere_button_toggled(toggled_on: bool) -> void:
	atmosphere_visible = toggled_on


func _on_main_menu_button_pressed() -> void:
	$MainMenu.show()


func _on_science_detail_item_selected(index: int) -> void:
	map_detail = Global.techs.keys()[index]


func _on_good_detail_item_selected(index: int) -> void:
	if !map_detail is Array: map_detail = [index,goods.keys()[0]]
	else: map_detail[0] = index


func _on_good_detail_2_item_selected(index: int) -> void:
	if !map_detail is Array: map_detail = [0,goods.keys()[index]]
	else: map_detail[1] = goods.keys()[index]


func _on_law_detail_item_selected(index: int) -> void:
	map_detail = law_categories[index]


func _on_multiplayer_synchronizer_synchronized() -> void:
	pass


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	pass # Replace with function body.
