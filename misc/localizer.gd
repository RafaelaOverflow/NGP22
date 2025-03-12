extends Node
class_name Localizer

@export var to_localize : Array[LocalizerTarget]

func _ready() -> void:
	_update_localization()
	Global.localization_update.connect(_update_localization)

func _update_localization() -> void:
	for t in to_localize:
		get_node(t.node).set(t.var_id,Global.localize(t.loc_id))
