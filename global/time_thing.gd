extends Control
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

@export var speed = 0
@export var last = 0
func _process(delta: float) -> void:
	if !Global.is_host: return
	if Input.is_action_just_pressed("pause"):
		if speed != 0:
			last = speed
			set_speed(0)
		else:
			set_speed(last)
	for i in 9:
		i+=1
		if Input.is_action_just_pressed("%s"%i):
			set_speed(i)
	if Input.is_action_just_pressed("timedown"):
		set_speed(max(0,speed-1))
	if Input.is_action_just_pressed("timeup"):
		set_speed(min(speed+1,9))

func set_speed(_speed):
	speed = _speed
	Global.time_scale = [0,0.01,0.1,1.0,10.0,50.0,100.0,1000.0,10000.0,100000.0][speed]
	texture_progress_bar.value = speed
