extends PanelContainer


func _on_quit_button_pressed() -> void:
	Global.quit()


func _on_continue_button_pressed() -> void:
	hide()


func _on_new_game_pressed() -> void:
	Global.system_creation_menu.show()
	hide()


func _on_save_file_dialog_file_selected(path: String) -> void:
	var f = FileAccess.open(path,FileAccess.WRITE)
	var s = {}
	Global.time_scale = 0.0
	for t in Global.task_threads:
		if t is ContinuousThread:
			t.pause = true
	while true:
		var i = true
		for t in Global.task_threads:
			if t is ContinuousThread:
				if !t.is_paused: i = false
		if i: break
		await Global.tree.process_frame
	
	s.planets = []
	for cb in Global.tree.get_nodes_in_group("celestial_body"):
		if cb is Planet:
			s.planets.append(cb.get_save_data())
	
	s.polities = []
	for p : Polity in Global.polities.values():
		s.polities.append(p.get_save_data())
	
	f.store_var(s)
	for t in Global.task_threads:
		if t is ContinuousThread:
			t.pause = false

func _on_save_button_pressed() -> void:
	$SaveFileDialog.popup_centered()


func _on_load_button_pressed() -> void:
	$LoadFileDialog.popup_centered()


func _on_load_file_dialog_file_selected(path: String) -> void:
	Global.clean_solar_system()
	var f = FileAccess.open(path,FileAccess.READ)
	var s = f.get_var()
	var star = preload("res://star/star.tscn").instantiate()
	star.scale = Vector3(139.268,139.268,139.268)
	Global.solar_system.add_child.call_deferred(star)
	for p in s.planets:
		var pl = Planet.from_save_data(p)
		pl.orbit_around = star
		Global.solar_system.add_child(pl)
	Global.polities.clear()
	for p in s.polities:
		Global.polities[p.id] = Polity.from_save_data(p)


func _on_host_button_pressed() -> void:
	Global.peer.create_server(25555)
	multiplayer.multiplayer_peer = Global.peer


func _on_join_button_pressed() -> void:
	Global.peer.create_client("localhost",25555)
	multiplayer.multiplayer_peer = Global.peer
