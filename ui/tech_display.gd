extends PanelContainer

@onready var label: Label = $VBoxContainer/Label
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
var tile_ref : WeakRef = weakref(null)
var tech_id : StringName
var lines : Dictionary[StringName,Line2D] = {}

func create(tech : Tech, tile : PlanetTile):
	tech_id = tech.id
	tile_ref = weakref(tile)
	label.text = Global.localize("tech.%s" % tech.id)
	position = tech.tech_tree_pos*300.0
	for r : Requirement in tech.requirements:
		if r.type == Requirement.TECH:
			var t = Global.techs[r.tech]
			var pos = t.tech_tree_pos * 300
			var pl = pos-position
			var l2d = Line2D.new()
			l2d.add_point(Vector2.ZERO)
			l2d.add_point(pl)
			add_child(l2d)
			l2d.position = Vector2(75,25)
			l2d.default_color = Color.WHITE if tile.has_tech(t.id) else Color.BLACK
			l2d.z_index = -10
			lines[t.id] = l2d
	modulate = Color.WHITE if tile.has_tech(tech.id) else Color.DIM_GRAY
	progress_bar.value = tile.techs.get(tech_id,0.0)

func _process(delta: float) -> void:
	var tile = tile_ref.get_ref()
	if tile is PlanetTile:
		progress_bar.value = tile.techs.get(tech_id,0.0)
		modulate = Color.WHITE if tile.has_tech(tech_id) else Color.DIM_GRAY
		for key in lines.keys():
			lines[key].default_color = Color.WHITE if tile.has_tech(key) else Color.BLACK


func _on_button_pressed() -> void:
	Global.map_mode = 8
	Global.map_detail = tech_id
	Global.science_detail.selected = Global.techs.keys().find(tech_id)
