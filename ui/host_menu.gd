extends PanelContainer

@onready var line_edit: LineEdit = $VBoxContainer/LineEdit
@onready var spin_box: SpinBox = $VBoxContainer/SpinBox
@onready var spin_box_2: SpinBox = $VBoxContainer/SpinBox2
@onready var spin_box_3: SpinBox = $VBoxContainer/SpinBox3

func _on_button_pressed() -> void:
	Global.server.create(line_edit.text,spin_box.value,spin_box_2.value,spin_box_3.value)
	hide()
