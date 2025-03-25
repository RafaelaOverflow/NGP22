extends PanelContainer

var b_ref : WeakRef
var t_ref : WeakRef
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var building_capacity_label: Label = $VBoxContainer/HBoxContainer/ProgressBar/BuildingCapacityLabel
@onready var building_capacity_bar: ProgressBar = $VBoxContainer/HBoxContainer/ProgressBar
@onready var size_label: Label = $VBoxContainer/SizeLabel
var consume = []
var produce = []
@onready var consume_vbox: VBoxContainer = $VBoxContainer/ConsumeVbox
@onready var produce_vbox: VBoxContainer = $VBoxContainer/ProduceVbox

func create(b:Building,tile:PlanetTile):
	b_ref = weakref(b)
	t_ref = weakref(tile)
	var bt = Global.building_types[b.type]
	for key in bt.consume.keys():
		var button = Button.new()
		var g = Global.goods[key]
		button.icon = g.texture
		button.pressed.connect(consume_button.bind(button))
		consume_vbox.add_child(button)
		consume.append(button)
	consume_vbox.visible = consume.size() != 0
	for key in bt.produce.keys():
		var button = Button.new()
		var g = Global.goods[key]
		button.icon = g.texture
		button.pressed.connect(produce_button.bind(button))
		produce_vbox.add_child(button)
		produce.append(button)
	produce_vbox.visible = produce.size() != 0

func update():
	var b = b_ref.get_ref()
	var tile = t_ref.get_ref()
	if b is Building:
		name_label.text = Global.localize("building.%s" % b.type)
		var bt = Global.building_types[b.type]
		size_label.text = "%s/%s" % [b.size,bt.get_limit(tile)+b.size]
		building_capacity_bar.value = float(b.get_total_hired())/float(b.get_total_hiring_limit())
		building_capacity_label.text = "%s/%s" % [b.get_total_hired(),b.get_total_hiring_limit()]
		var tl =  b.get_total_hiring_limit()
		if tl == 0: return
		var h = float(b.get_total_hired()) / float(tl)
		var i = 0
		for key in bt.consume.keys():
			var button = consume[i]
			button.text = "%s" % (bt.consume[key]*float(b.size)*h)
			button.tooltip_text = "%s - $%.2f" % [Global.localize("good.%s" % key),tile.good_prices.get(key)]
			i+=1
		i=0
		for key in bt.produce.keys():
			var button = produce[i]
			button.text = "%s" % (bt.produce[key]*float(b.size)*h)
			button.tooltip_text = "%s - $%.2f" % [Global.localize("good.%s" % key),tile.good_prices.get(key)]
			i+=1

func _process(delta: float) -> void:
	update()


func _on_pop_button_pressed() -> void:
	Global.pop_display.display(b_ref.get_ref())

func consume_button(button):
	var i = consume.find(button)
	var b = b_ref.get_ref()
	if b is Building:
		var bt = Global.building_types[b.type]
		Global.map_mode = 10
		var g = bt.consume.keys()[i]
		Global.map_detail = [0,g]
		Global.good_detail.selected = 0
		Global.good_detail_2.selected = Global.goods.keys().find(g)

func produce_button(button):
	var i = produce.find(button)
	var b = b_ref.get_ref()
	if b is Building:
		var bt = Global.building_types[b.type]
		Global.map_mode = 10
		var g = bt.produce.keys()[i]
		Global.map_detail = [1,g]
		Global.good_detail.selected = 1
		Global.good_detail_2.selected = Global.goods.keys().find(g)
