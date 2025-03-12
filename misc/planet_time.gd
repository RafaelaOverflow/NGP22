extends RefCounted
class_name PlanetTime

var yp : int = 0
var yd : int = 0
var y : int = 0

func add(t:int) -> void:
	yp += t
	if yp > yd:
		var a = (yp/yd)
		y += a
		yp -= a*yd

func get_day() -> int:
	return yp+1
func get_year() -> int:
	return y

func get_save_data() -> Dictionary:
	return {"yp" : yp, "yd" : yd, "y" : y}

static func from_save_data(s) -> PlanetTime:
	var pt = PlanetTime.new()
	pt.yp = s.yp
	pt.yd = s.yd
	pt.y = s.y
	return pt
