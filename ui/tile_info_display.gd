extends PanelContainer

var tile_ref : WeakRef = weakref(null)
var planet_ref : WeakRef = weakref(null)
@onready var color_rect: ColorRect = $TabContainer/Tile/VBoxContainer/ColorRect
@onready var tile_label: Label = $TabContainer/Tile/VBoxContainer/Label
@onready var tile_vbox : VBoxContainer = $TabContainer/Tile/VBoxContainer
@onready var planet_label : Label = $TabContainer/Planet/Label
@onready var system_label : Label = $TabContainer/System/Label
@onready var region_label: Label = $TabContainer/Region/VBoxContainer/Label

func display(tile,planet):
	show()
	tile_ref = weakref(tile)
	planet_ref = weakref(planet)
	$TabContainer.current_tab = 3
	if Global.map_mode == 12: $TabContainer.current_tab = 2
	

func _process(delta: float) -> void:
	var planet = planet_ref.get_ref()
	var tile = tile_ref.get_ref()
	if planet != null and tile != null:
		match $TabContainer.current_tab:
			3:
				color_rect.color = tile.get_color(planet.data)
				color_rect.custom_minimum_size = Vector2(1,1) * tile_vbox.size.x
				color_rect.size = Vector2(1,1) * tile_vbox.size.x
				tile_label.text = "ID: %s\nAltitude: %.2f m\nHumidity: %s\nTemperature: %.2f °C\nForestation: %.2f%s\nArea: %.2f km²\nLand Used: %.2f km2\nIs Ocean: %s\nPopulation: %s\nPopulation Capacity: %s" % [tile.id,tile.get_altitude(planet.data),("%.2f" % tile.get_humidity(planet.data))+"%",tile.get_temperature(planet),tile.get_forestation(planet.data),"%",planet.data.area_per_tile,tile.get_modifier(PlanetTile.LAND_USE),tile.is_ocean(planet.data),tile.get_total_pop(),tile.get_pop_capacity(planet.data)]
			2:
				var region : PlanetRegion = tile.get_region(planet.data)
				region_label.text = "ID: %s\nIs Ocean: %s\nTile Count: %s\nArea: %.2f km²\nPopulation: %s" % [tile.region,region.is_ocean,region.tiles.size(),planet.data.area_per_tile*region.tiles.size(),region.pop]
			1:
				planet_label.text = "Radius: %.2f km\nSurface Area: %.2f km²\nOcean Level: %.2f\nOrbit: %.2f (%.2fAU)\nYear Length: %s\nYear: %s\nDay: %s\nPopulation: %s" % [planet.data.radius,planet.data.area,planet.data.ocean_level,planet.cd,planet.cd/Global.AU,planet.pt.yd,planet.pt.get_year(),planet.pt.get_day(),planet.data.pop]
			0:
				pass

func _on_forest_button_pressed() -> void:
	var tile = tile_ref.get_ref()
	tile.forest = min(1.0,0.1)


func _on_pop_button_pressed() -> void:
	var planet = planet_ref.get_ref()
	var tile = tile_ref.get_ref()
	if planet != null and tile != null:
		tile.pops.append(POP.new(100))
	


func _on_polities_button_pressed() -> void:
	Global.polities_display.display(null)


func _on_building_button_pressed() -> void:
	Global.building_display.display(tile_ref.get_ref())


func _on_tech_button_pressed() -> void:
	Global.tech_tree.display(tile_ref.get_ref())


func _on_pop_display_button_pressed() -> void:
	Global.pop_display.display(tile_ref.get_ref().pops)
