extends CharacterBody3D
class_name CelestialBody

@export var mass = 10
var v = Vector3.ZERO

func _ready() -> void:
	add_to_group("celestial_body")
