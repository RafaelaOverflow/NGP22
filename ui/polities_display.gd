extends Control
@onready var tab: TabContainer = $Tab
@onready var polities_container : HFlowContainer = $"Tab/All Polities/HFlowContainer"
@onready var label: Label = $Tab/Polity/VBoxContainer/Label
var polity = null
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
					label.text = "%s\n" % p.id
					label.text += "Territories %s\n" % p.territories.size()
					label.text += "Population %s" % p.get_pop() 

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
	show()

func _on_button_pressed() -> void:
	hide()
