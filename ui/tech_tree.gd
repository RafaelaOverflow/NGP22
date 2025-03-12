extends Control

@onready var camera_2d: Camera2D = $TreeDisplay/SubViewport/Camera2D
@onready var node_2d: Node2D = $TreeDisplay/SubViewport/Node2D
@onready var sub_viewport: SubViewport = $TreeDisplay/SubViewport
@onready var tree_display: SubViewportContainer = $TreeDisplay

func display(tile:PlanetTile):
	show()
	Util.clean_children(node_2d)
	for tech : Tech in Global.techs.values():
		var d = preload("res://ui/tech_display.tscn").instantiate()
		node_2d.add_child(d)
		d.create(tech,tile)

var mouse_pos := Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.relative

func _process(delta: float) -> void:
	if visible: 
		sub_viewport.size = tree_display.size
		if mouse_on:
			var z = clamp(camera_2d.zoom.x-Input.get_axis("zoom+","zoom-")*delta,0.5,2.0)
			camera_2d.zoom = Vector2(z,z)
			if Input.is_action_pressed("click"):
				#mouse_pos *= 0.0025
				var yaw = mouse_pos.x
				var pitch = mouse_pos.y
				mouse_pos = Vector2.ZERO
				node_2d.position.y = clamp(node_2d.position.y + pitch, -20000,20000)
				node_2d.position.x = clamp(node_2d.position.x + yaw, -20000,20000)
				



var mouse_on = false
func _on_tree_display_mouse_entered() -> void:
	mouse_on = true

func _on_tree_display_mouse_exited() -> void:
	mouse_on = false


func _on_button_pressed() -> void:
	hide()
