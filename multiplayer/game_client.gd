extends RefCounted
class_name GameClient

var id = ""
var peer := ENetMultiplayerPeer.new()
var message = {}
var tcp_messanger = StreamPeerTCP.new()
var messanger_connected := false
var sync = {}
var sync_buffer : PackedByteArray = []
var tcp_sync = StreamPeerTCP.new()
var sync_connected := false

func create(ip,port_mu,port_m,port_s):
	peer.create_client(ip,port_mu)
	Global.multiplayer.multiplayer_peer = peer
	Global.is_host = false
	tcp_messanger.connect_to_host(ip,port_m)
	tcp_sync.connect_to_host(ip,port_s)
	id = Global.multiplayer.get_unique_id()

var f = 0
func update():
	tcp_messanger.poll()
	tcp_sync.poll()
	if !messanger_connected:
		var s = tcp_messanger.get_status()
		if s == 2:
			messanger_connected = true
			tcp_messanger.put_var(id)
	if !sync_connected:
		var s = tcp_sync.get_status()
		if s == 2:
			sync_connected = true
			tcp_sync.put_var(id)
	if messanger_connected and sync_connected:
		update_message()
		var client_state = {"need_sync" : false}
		tcp_sync.poll()
		var abytes = tcp_sync.get_available_bytes()
		f+=1
		Global.get_node("Label").text = "%s - %s" % [abytes,f]
		if abytes > 0:
			sync_buffer.append_array(tcp_sync.get_partial_data(abytes)[1])
		else:
			if !sync_buffer.is_empty():
				var v2 = sync_buffer.decompress(message.sync_size,FileAccess.COMPRESSION_FASTLZ)
				var v = bytes_to_var(v2)
				if v is Dictionary:
					Util.delta_load_dict(sync,v)
					if Global.tree.get_nodes_in_group("planet").size() < sync.size():
						Global.clean_solar_system()
						var star = preload("res://star/star.tscn").instantiate()
						star.scale = Vector3(139.268,139.268,139.268)
						Global.solar_system.add_child.call_deferred(star)
						for s in sync.p.values():
							var p = Planet.from_save_data(s)
							p.orbit_around = star
							Global.solar_system.add_child(p)
					for p in sync.pol.keys():
						if Global.polities.has(p):
							Global.polities[p].sync(sync.pol[p])
						else:
							Global.polities[p] = Polity.from_save_data(sync.pol[p])
					for key in Global.polities.keys():
						if !sync.pol.has(key): Global.polities.erase(key)
				sync_buffer.clear()
			f=0
			client_state.need_sync = true
		tcp_messanger.put_var(client_state)

func update_message():
	if !tcp_messanger.get_available_bytes() > 0: return
	var m = tcp_messanger.get_var()
	if m is Dictionary: Util.delta_load_dict(message,m)
