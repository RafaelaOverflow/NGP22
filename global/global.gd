extends Node

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
var map_mode = 0
var map_detail = null
var t :int= 0
var t_progress :float= 0.0
var t_limit : int = 99999999
var polities : Dictionary[int,Polity] = {}
@export var techs : Dictionary[StringName,Tech] = {}
@export var building_types : Dictionary[StringName,BuildingType] = {}
@export var resource_types : Dictionary[StringName,ResourceType] = {}


@export var base_noise : Dictionary[StringName,FastNoiseLite] = {}

@onready var polities_display: Control = $PolitiesDisplay
@onready var building_display: Control = $BuildingDisplay
@onready var tech_tree: Control = $TechTree

@onready var science_detail: OptionButton = $HBoxContainer/ScienceDetail

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
	"theme" : &"default"
}

func _ready() -> void:
	tree = get_tree()
	for tech in Global.techs.keys():
		science_detail.add_item(tech)
	load_settings()
	load_localization()

func update_localization():
	var i = 0
	for key in techs.keys():
		science_detail.set_item_text(i,localize("tech.%s" % key))
		i+=1
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

var lts = 0
func _process(delta: float) -> void:
	science_detail.visible = map_mode == 8
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
	if cam != null:
		if cam.camera_mode == 1:
			if cam.focus.get_ref() != null:
				var n : CelestialBody = cam.focus.get_ref()
				if n is Planet:
					$Label.text = "%s - %s" % [n.p,t]
	if Input.is_action_just_pressed("leave") and cam.camera_mode != 1:
		$MainMenu.show()
	

func display_tile_info(tile : PlanetTile,planet):
	$TileInfoDisplay.display(tile,planet)

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
		var x = 7419.0
		for i in 4:
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
			p.cd = x
			p.orbit_around = star
			p.data = pd
			p.pid = i
			pd.mesh_resolution = info.get("planet_mesh_resolution",8)
			pd.texture_resolution = info.get("planet_resolution",8)
			#pd.mesh_resolution = clamp(pd.texture_resolution,3,32)
			pd.ocean_level = 0.5
			pd.gen_tiles(p)
			x+= 7419.0
			solar_system.add_child.call_deferred(p)
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
