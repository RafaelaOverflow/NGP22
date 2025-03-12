extends RefCounted
class_name TaskThread

var actual_thread := Thread.new()
var callable : Callable

var finished = false

func _init(call : Callable,priority = 0) -> void:
	callable = call
	Global.task_threads.append(self)
	actual_thread.start(do,priority)

func do():
	callable.call()
	finished = true
