extends Camera3D

var camera_mode = 0
var focus : WeakRef = weakref(null)
@onready var ray: RayCast3D = $RayCast3D


func _process(delta: float) -> void:
	pass
	#

func do(delta):
	$Label2.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.is_action_pressed("capture") else Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("switch_focus"):
		if focus.get_ref() == null or camera_mode == 0:
			var i = Global.tree.get_first_node_in_group("celestial_body")
			if i == null: return
			camera_mode = 1
			focus = weakref(i)
			var n = focus.get_ref().get_node("CameraHolder").get_child(0)
			n.position.z = 5.0
		else:
			var cbs = Global.tree.get_nodes_in_group("celestial_body")
			var f = focus.get_ref()
			var i = cbs.find(f)
			focus = weakref(cbs[posmod(i+1,cbs.size())])
	if Input.is_action_just_pressed("leave"): camera_mode = 0
	
	match camera_mode:
		0:
			if Input.is_action_pressed("capture"):
				var vec = Input.get_vector("left","right","down","up")
				vec = Vector3(vec.x,vec.y,Input.get_axis("foward","back"))
				vec = vec.x*basis.x+vec.y*basis.y+vec.z*basis.z
				position += vec
				look(self,delta)
		1:
			if focus.get_ref() == null:
				camera_mode = 0
				return
			var n : CelestialBody = focus.get_ref()
			if n is Planet:
				$Label2.text = "Year %s - Day %s" % [n.pt.get_year(),n.pt.get_day()]
			var ch = n.get_node("CameraHolder")
			var npos = ch.get_child(0)
			global_position = npos.global_position
			look_at(n.global_position)
			if mouse_in: npos.position.z = max(1.0,(Input.get_axis("zoom+","zoom-")*delta*npos.position.z)+npos.position.z)
			if Input.is_action_pressed("capture"):
				look(ch,delta)
				
			

func _physics_process(delta: float) -> void:
	do.call_deferred(delta)
	do_physics.call_deferred(delta)

@onready var panel: Panel = $Label/Panel
@onready var label: Label = $Label
func do_physics(delta):
	var mp = get_viewport().get_mouse_position()
	ray.target_position = project_local_ray_normal(mp)*100.0
	ray.force_raycast_update()
	var col = ray.get_collider()
	label.text = ""
	if col != null:
		label.position = mp
		var p = ray.get_collision_point()
		var n = ray.get_collision_normal()
		#$MeshInstance3D.global_position = p
		if col is Planet:
			var dir = Vector3.ZERO.direction_to(col.to_local(p))
			var tile = col.data.tiles[Util.sphere_pos_to_tile_id(dir,col.data.texture_resolution)]
			if mouse_in:
				match Global.map_mode:
					0:
						pass
					1:
						label.text = "%.2f m" % tile.get_altitude(col.data)
					2:
						label.text = "%.2f °C" % tile.get_temperature(col)
					3:
						label.text = "%s" % tile.get_total_pop()
					4:
						label.text = "%s" % tile.id
					5:
						label.text = ("%.2f" % tile.get_forestation(col.data))+"%"
					6:
						label.text = ("%.2f" % tile.get_humidity(col.data))+"%"
					7:
						if tile.polity != null:
							var pol : Polity = tile.get_polity()
							label.text = ("%s" % pol.get_name())
							if pol.capital == tile: label.text+=" - Capital"
					8:
						if Global.map_detail is StringName: label.text = ("%.2f" % (tile.techs.get(Global.map_detail,0.0)*100.0))+"%"
					9:
						label.text = ("%.2f km² - " % tile.get_modifier(PlanetTile.LAND_USE))+("%.2f" % (tile.get_modifier(PlanetTile.LAND_USE)/col.data.area_per_tile))+"%"
					10:
						if Global.map_detail is Array:
							match Global.map_detail[0]:
								0:
									label.text = "%.2f" % tile.consume.get(Global.map_detail[1],0)
								1:
									label.text = "%.2f" % tile.produce.get(Global.map_detail[1],0)
								2:
									label.text = "$%.2f" % tile.good_prices.get(Global.map_detail[1],Global.goods[Global.map_detail[1]].base_price*0.2)
					11:
						if Global.map_detail is StringName:
							if tile.polity != null:
								var pol = tile.get_polity()
								label.text = "%s" % Global.localize("law.%s" % pol.laws[Global.map_detail])
					12:
						label.text = "Region ID: %s" % tile.region
				if Input.is_action_just_pressed("click"):
					Global.display_tile_info(tile,col)
					match Global.map_mode:
						7:
							if tile.polity != null: Global.polities_display.display(tile.polity)
				
	label.visible = !label.text.is_empty()
	panel.size = label.size

var using_controller = false
func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.relative
		using_controller = false
	if event is InputEventJoypadMotion:
		using_controller = true

const p_limit = 85.0
var mouse_pos := Vector2.ZERO
func look(obj,delta):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_pos *= 0.25
		var yaw = mouse_pos.x
		var pitch = mouse_pos.y
		mouse_pos = Vector2.ZERO
		#if using_controller:
			#var vec = Input.get_vector("look_left","look_right","look_up","look_down")
			#yaw = vec.x * 100 * delta
			#pitch = vec.y * 100 * delta
		
		pitch = pitch
		#totalPitch = clamp(rotation_degrees.x,-p_limit,p_limit)
		#pitch = clamp(deg_to_rad(pitch), -1.5 - rotation.x, 1.5 + rotation.x)
		obj.rotate_y(deg_to_rad(-yaw))
		obj.rotate_object_local(Vector3(1,0,0),deg_to_rad(-pitch))

var mouse_in = false
func _on_control_mouse_entered() -> void:
	mouse_in = true

func _on_control_mouse_exited() -> void:
	mouse_in = false
