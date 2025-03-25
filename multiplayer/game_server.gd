extends RefCounted
class_name GameServer

var peer := ENetMultiplayerPeer.new()
var message_server = TCPServer.new()
var sync_server = TCPServer.new()
var clients : Dictionary[int,GameConnection] = {}
var to_clientize_m : Array[StreamPeerTCP]
var to_clientize_s : Array[StreamPeerTCP]

var sync = {}

func create(ip,port_mu,port_me,port_sy):
	peer.create_server(port_mu)
	Global.multiplayer.multiplayer_peer = peer
	message_server.listen(port_me)
	sync_server.listen(port_sy)
	Global.is_host = true

func update():
	if message_server.is_connection_available():
		to_clientize_m.append(message_server.take_connection())
	if sync_server.is_connection_available():
		to_clientize_s.append(sync_server.take_connection())
	for p in to_clientize_m:
		p.poll()
		if p.get_status() != 2: continue
		var v = p.get_var()
		if v != null:
			if !clients.has(v): clients[v] = GameConnection.new()
			clients[v].tcp_messanger = p
			to_clientize_m.erase(p)
	for p in to_clientize_s:
		p.poll()
		if p.get_status() != 2: continue
		var v = p.get_var()
		if v != null:
			if !clients.has(v): clients[v] = GameConnection.new()
			clients[v].tcp_sync = p
			to_clientize_s.erase(p)
	var nsync = {"p":{}, "pol":{}}
	for planet : Planet in Global.tree.get_nodes_in_group("planet"):
		nsync.p[planet.pid] = planet.get_save_data(true)
	for key in Global.polities.keys():
		nsync.pol[key] = Global.polities[key].get_save_data()
	sync = nsync
	for key : int in clients.keys():
		var client = clients[key]
		var i = client.update()
		if client.state == GameConnection.INCOMPLETE: continue
		if i[0] and client.message.get("need_sync",false):
			client.fsync()
