extends TaskThread
class_name ContinuousThread
var continuar = true
var await_process = true
var pause = false
var is_paused = false

signal paused

func _init(call,priority = 0) -> void:
	callable = call
	Global.task_threads.append(self)
	actual_thread.start(do,Thread.PRIORITY_LOW)

func do():
	while continuar and callable != null:
		callable.call()
		if pause:
			paused.emit.call_deferred()
			is_paused = true
			while pause:
				await Global.tree.process_frame
			is_paused = false
		if await_process: await Global.tree.process_frame
	finished = true
