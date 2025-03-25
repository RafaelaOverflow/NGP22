extends Label
class_name ChatMessage

var t = 20.0

func _process(delta: float) -> void:
	t -= delta
	if t <= 0:
		get_parent().remove_child(self)
		queue_free()
	elif t <= 10.0:
		var b = t/10.0
		self_modulate.a = b
