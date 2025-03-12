extends Control

@onready var hflow: HFlowContainer = $"All Polities/HFlowContainer"

var to_display : WeakRef = weakref(null)

func display(_to_display):
	to_display = weakref(_to_display)
	show()
	update()

func _process(delta: float) -> void:
	if visible:
		pass

func update():
	var obj = to_display.get_ref()
	if obj != null:
		for child in hflow.get_children():
			remove_child(child)
			child.queue_free()
		if obj is PlanetTile:
			for b : Building in obj.buildings.values():
				var t = Global.building_types[b.type]
				var label = Label.new()
				label.text = Global.localize("building.%s" % b.type)
				label.text += "\nSize %s" % b.size
				label.text += ("\nLand Use %.2f" % [float(b.size)*t.land_use]) 
				for m : Modifier in t.modifiers:
					label.text += "\n%s - %s" % [m.target, m.scaled(b.size)]
				hflow.add_child(label)

func _on_button_pressed() -> void:
	hide()
