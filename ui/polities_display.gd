extends Control
@onready var tab: TabContainer = $Tab
@onready var polities_container : HFlowContainer = $"Tab/All Polities/HFlowContainer"
@onready var label: Label = $Tab/Polity/VBoxContainer/Label
var polity = null
@onready var law_container : HFlowContainer = $Tab/Polity/VBoxContainer/HFlowContainer
var law_displays = []

func _ready() -> void:
	pass

func law_selected(index,law_list):
	if polity == null: return
	Global.polities[polity].set_law(law_list[index].id)

func _process(delta: float) -> void:
	if visible:
		match tab.current_tab:
			0:
				pass
			1:
				if polity != null:
					var p = Global.polities.get(polity)
					if p == null:
						polity = null
						return
					label.text = "%s" % p.id
					label.text += "\nTerritories %s" % p.territories.size()
					label.text += "\nPopulation %s" % p.get_pop()
					#label.text += "\nLaws %s" % p.laws
					label.text += "\nGovernment Type %s" % Global.localize("gov_type.%s" % p.gov_type)
					var i = 0
					for category in Global.law_categories:
						law_displays[i].get_node("Label").text = Global.localize("law.%s" % p.laws[category])
						i += 1

func display(_polity):
	polity = _polity
	if polity == null:
		tab.current_tab = 0
	else:
		tab.current_tab = 1
		polity = _polity
	for child in polities_container.get_children():
		polities_container.remove_child(child)
		child.queue_free()
	for p in Global.polities.values():
		var button = Button.new()
		button.text = "%s" % p.id
		button.connect("pressed",display.bind(p.id))
		polities_container.add_child(button)
	law_displays = []
	Util.clean_children(law_container)
	for category in Global.law_categories:
		var ld = preload("res://ui/law_display.tscn").instantiate()
		law_container.add_child(ld)
		law_displays.append(ld)
		var b : MenuButton = ld.get_node("MenuButton")
		var l = []
		for law : Law in Global.laws.values():
			if law.category == category: 
				l.append(law)
				b.get_popup().add_item(Global.localize("law.%s" % law.id))
		b.get_popup().connect("index_pressed",law_selected.bind(l))
	show()

func _on_button_pressed() -> void:
	hide()
