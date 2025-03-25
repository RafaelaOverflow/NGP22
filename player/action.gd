extends RefCounted
class_name Action

static func queue_action(action):
	if Global.is_host:
		Global.server.actions.append(action)
	else:
		Global.client.actions.append(action)

static func create_action(player_id:int,action_id:int,args:=[]) -> Array:
	return [player_id,action_id,args]

enum {
	ADD_POP,
	ADD_FOREST,
	CHAT,
	SET_LAW
}

static var f : Dictionary[int,Callable] = {
	ADD_POP : func(player_id,args):
		var tile = Global.get_tile(args[0])
		tile.pops.append(POP.new(100)),
	ADD_FOREST : func(player_id,args):
		var tile = Global.get_tile(args[0])
		tile.forest = min(1.0,0.1+tile.forest),
	CHAT : func(player_id,args):
		Global.chat.add_message("<%s> %s" % [player_id,args[0]]),
	SET_LAW : func(player_id,args):
		var p = Global.polities.get(args[0])
		if p is Polity:
			p.set_law(args[1])
}

static func act(action):
	var player_id = action[0]
	var action_id = action[1]
	var args = action[2]
	f[action_id].call(player_id,args)
