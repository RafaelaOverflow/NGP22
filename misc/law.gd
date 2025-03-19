extends Resource
class_name Law

@export var id : StringName
@export var category : StringName
@export var map_color : Color = Color.WHITE
@export var requirements : Array[Requirement] = []
@export var modifiers : Array[Modifier] = []
@export var on_set : Array[Event] = []
