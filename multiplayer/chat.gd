extends Control

@onready var vbox : VBoxContainer = $ScrollContainer/VBoxContainer/VBoxContainer
@onready var line_edit: LineEdit = $ScrollContainer/VBoxContainer/LineEdit

var i = 0
func add_message(text):
	var m = preload("res://multiplayer/chat_message.tscn").instantiate()
	m.text = text
	m.name = "m%s" % i
	vbox.add_child(m)
	i+=1

func _process(delta: float) -> void:
	pass


func _on_line_edit_text_submitted(new_text: String) -> void:
	Action.queue_action(Action.create_action(Global.client.id,Action.CHAT,[new_text]))
	line_edit.clear()
