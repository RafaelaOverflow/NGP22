extends Control

@onready var planet: Planet = $ScrollContainer/VBoxContainer/HBoxContainer/SubViewportContainer/SubViewport/Planet

var info = {
	"planet_resolution" : 8,
	"planet_mesh_resolution" : 32,
	"moon_percent" : 0.4
}

func _ready() -> void:
	update_show_planet()

func _process(delta: float) -> void:
	planet.rotate_y(delta)


func planet_resolution_value_changed(value: float) -> void:
	info.planet_resolution = value
	$ScrollContainer/VBoxContainer/PlanetResolution/Label2.text = "%sx%sx6 = %s" % [value,value,value*value*6]
	update_show_planet()


func _create_pressed() -> void:
	Global.create_solar_system(info)
	hide()


func _on_seed_changed(new_text: String) -> void:
	info.seed = new_text.hash()

func update_show_planet():
	Global.random = RandomNumberGenerator.new()
	var nt = ["base","base","type2"]
	for n in nt.size():
		Global.gen_temp["noise%s" % n] = Global.base_noise[nt[n]].duplicate()
		Global.gen_temp["noise%s" % n].seed = Global.random.randi()
	Global.gen_temp["rnoises"] = []
	for r in Global.resource_types.values():
		var n = Global.base_noise.base.duplicate()
		n.seed = Global.random.randi()
		Global.gen_temp.rnoises.append(n)
	var pd := PlanetData.new()
	planet.data = pd
	pd.mesh_resolution = info.get("planet_mesh_resolution",8)
	pd.texture_resolution = info.get("planet_resolution",8)
	#pd.mesh_resolution = clamp(pd.texture_resolution,3,32)
	pd.ocean_level = 0.5
	pd.gen_tiles(planet)
	if info.get("show_planet_forest",false):
		for t : PlanetTile in pd.tiles.values():
			t.forest = t.humidity
	for face in planet.faces:
		face.regenerate_mesh(planet.data)


func _on_show_atmosphere_slider_value_changed(value: float) -> void:
	planet.data.atmosphere = value
	planet.atmosphere.set_instance_shader_parameter("a",planet.data.atmosphere)


func _planet_mesh_resolution_value_changed(value: float) -> void:
	info.planet_mesh_resolution = value
	#$ScrollContainer/VBoxContainer/PlanetResolution/Label2.text = "%sx%sx6 = %s" % [value,value,value*value*6]
	update_show_planet()


func _show_planet_forest_toggled(toggled_on: bool) -> void:
	info.show_planet_forest = toggled_on
	update_show_planet()


func _planet_count(value: float) -> void:
	info.planet_amount = int(value)


func _moon_percent(value: float) -> void:
	info.moon_percent = (value*0.01)
