extends Control

@onready var hflow: HFlowContainer = $"All Polities/HFlowContainer"

var to_display : WeakRef = weakref(null)

func display(_to_display):
	to_display = weakref(_to_display)
	show()
	for child in hflow.get_children():
		remove_child(child)
		child.queue_free()
	update()

func _process(delta: float) -> void:
	if visible:
		update()

func update():
	var obj = to_display.get_ref()
	if obj != null:
		if obj is PlanetTile:
			for b : Building in obj.buildings.values():
				if has_building(b): continue
				#var t = Global.building_types[b.type]
				#var label = Label.new()
				#label.text = Global.localize("building.%s" % b.type)
				#label.text += "\nSize %s" % b.size
				#label.text += ("\nLand Use %.2f" % [float(b.size)*t.land_use])
				#label.text += ("\nHired %s/%s") % [b.get_total_hired(),b.get_total_hiring_limit()]
				#for m : Modifier in t.modifiers:
					#label.text += "\n%s - %s" % [m.target, m.scaled(b.size)]
				#hflow.add_child(label)
				var ibd = preload("res://ui/individual_building_display.tscn").instantiate()
				hflow.add_child(ibd)
				ibd.create(b,obj)

func has_building(b : Building):
	for child in hflow.get_children():
		if child.b_ref.get_ref() == b: return true
	return false

func _on_button_pressed() -> void:
	hide()
