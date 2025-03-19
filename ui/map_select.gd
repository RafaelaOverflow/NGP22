extends Control

@onready var tech_option: OptionButton = $PanelContainer/ScrollContainer/HFlowContainer/TechButton/TechOptionButton

func _ready() -> void:
	for tech in Global.techs.keys():
		tech_option.add_item(tech)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("map"):
		visible = !visible


func _on_normal_button_pressed() -> void:
	Global.map_mode = 0
	hide()


func _on_altitude_button_pressed() -> void:
	Global.map_mode = 1
	hide()


func _on_temperature_button_pressed() -> void:
	Global.map_mode = 2
	hide()


func _on_pop_button_pressed() -> void:
	Global.map_mode = 3
	hide()


func _on_id_button_pressed() -> void:
	Global.map_mode = 4
	hide()


func _on_forest_button_pressed() -> void:
	Global.map_mode = 5
	hide()


func _on_humid_button_pressed() -> void:
	Global.map_mode = 6
	hide()


func _on_tech_option_button_item_selected(index: int) -> void:
	Global.map_detail = Global.techs.keys()[index]


func _on_tech_button_pressed() -> void:
	Global.map_mode = 8
	Global.map_detail = Global.techs.keys()[Global.science_detail.selected]
	hide()


func _on_polity_button_pressed() -> void:
	Global.map_mode = 7
	hide()


func _on_land_use_button_pressed() -> void:
	Global.map_mode = 9
	hide()


func _on_good_button_pressed() -> void:
	Global.map_mode = 10
	Global.map_detail = [Global.good_detail.selected,Global.goods.keys()[Global.good_detail_2.selected]]
	hide()


func _on_law_button_pressed() -> void:
	Global.map_mode = 11
	Global.map_detail = Global.law_categories[Global.law_detail.selected]
	hide()
