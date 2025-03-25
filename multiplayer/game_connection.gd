extends RefCounted
class_name GameConnection

enum {
	INCOMPLETE,
	COMPLETE
}
var state = INCOMPLETE
var message = {}
var tcp_messanger : StreamPeerTCP = null

var id = 0
var sync = {}
var tcp_sync : StreamPeerTCP = null

func update():
	var r = [false]
	if (tcp_messanger == null or tcp_sync == null):
		state = INCOMPLETE
		return r
	tcp_messanger.poll()
	if state == INCOMPLETE:
		state = COMPLETE
		Global.chat.add_message(Global.localize("multiplayer.join_message") % id)
	if tcp_messanger.get_available_bytes() > 0:
		var m = tcp_messanger.get_var()
		if m is Dictionary:
			r[0] = true
			Util.delta_load_dict(message,m)
	tcp_sync.poll()
	return r

signal s_thread_finish()
var to_send : PackedByteArray
var s_thread : WeakRef = weakref(null)
func fsync() -> void:
	if s_thread.get_ref() == null:
		s_thread = weakref(TaskThread.new(
			func():
				var delta = Util.delta_save_dict(sync,Global.server.sync.duplicate(true),true)
				Util.delta_load_dict(sync,delta)
				var tb = var_to_bytes(delta)#.compress(FileAccess.COMPRESSION_FASTLZ)
				var tbs = tb.size()
				tb = tb.compress(FileAccess.COMPRESSION_FASTLZ)
				s_thread_finish.emit([tb,tbs])
		))
		
		var tb = await s_thread_finish
		
		tcp_messanger.put_var({"sync_size":tb[1]})
		tcp_sync.put_partial_data(tb[0])
		message.need_sync = false
