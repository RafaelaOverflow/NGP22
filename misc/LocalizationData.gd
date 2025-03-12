extends RefCounted
class_name LocalizationData

var language_id = ""
var localization = {}

func _init(_language_id = "", _localization = {}):
	language_id = _language_id
	localization = _localization

func from_json(data):
	language_id = data.language_id
	localization = data.localization
	return self

func get_leng(text:String,start):
	var c = text.find("}}",start)
	var ns = text.find("{{",start)
	if ns != -1 and ns < c:
		while true:
			c = text.find("}}",ns)
			c = text.find("}}",c+2)
			ns = text.find("{{",c+2)
			if ns == -1 or c < ns: break
	return c - start

func double_colon_split(text:String):
	var indent = 0
	var array = []
	var i = 0
	while true:
		var dcp = text.find("::",i)
		if dcp == -1:
			array.append(text)
			break
		var c = text.find("}}",dcp)
		var s = text.find("{{",dcp)
		if c != -1 and (s == -1 or s > c):
			i = c+2
		else:
			i = 0
			var add = text.substr(0,dcp)
			array.append(add)
			text = text.trim_prefix(add+"::")
	return array

func localize(id,args = {}):
	var f = id.split(".")
	var text = localization
	for k : String in f:
		if k.begins_with("$"): 
			k = args.get(k.trim_prefix("$"))
			if k.contains("."):
				var k2 = k.split(".")
				for k3 : String in k2:
					if text.get(k3) == null:
						text = id
						break
					text = text.get(k3)
				continue
		if text.get(k) == null:
			text = id
			break
		text = text.get(k)
	return process_text(text,args)

func process_text(text : String, args : Dictionary) -> String:
	while "{{" in text:
		var start = text.find("{{") + 2
		var leng = get_leng(text,start)
		var code = text.substr(start,leng)
		var value = from_code(code,args)
		text = text.replace(text.substr(start-2,leng+4),str(value))
	return text

func from_code(code : String, args = {}):
	args.global = Global
	var divide = code.find("::")
	var pre = code.substr(0,divide)
	divide += 2
	var post = code.substr(divide, code.length()-divide)
	var f = {
		"arg" : func():
			return args.get(post),
		"rarg" : func():
			var v = args
			var s = post.split(".")
			for k in s:
				if v == null:
					return post
				v = v.get(k)
			return v,
		"%" : func():
			var s = post.split("::")
			var v = Global.recursive_get(s[0],args)
			return s[1] % v,
		"rget" : func():
			var x = double_colon_split(post)
			var v = args
			var s = x[0].split(".")
			for k in s:
				if v == null:
					return post
				v = v.get(k)
			if v == null: return x[1]
			return v,
		"map" : func():
			var s = double_colon_split(post)
			var v = Global.recursive_get(s[0],args)
			if !v is String: v = "%s" % v
			for i in range(1,s.size()):
				var s2 = s[i].split("==")
				if s2[0] == v: return s2[1]
			return "",
		"locmap" : func():
			var s = double_colon_split(post)
			var v = Global.recursive_get(s[1],args)
			return localize("%s.%s" % [s[0],v],args),
		"!locmap" : func():
			var s = double_colon_split(post)
			var v = Global.recursive_get(s[1],args)
			return localize("%s.%s" % [v,s[0]],args),
		"locarr": func():
			var s = double_colon_split(post)
			var loc_id = s[0]
			var g = s[1]
			var split = s[2]
			var arr = args.get(g)
			var t = ""
			if arr is Array:
				var size = arr.size()
				for i in size:
					if i != 0: t += split
					t += localize(loc_id,{"global":Global,g:arr[i],"args":args})
			return t,
		"loc" : func():
			if post.begins_with("$"):
				post = Global.recursive_get(post.trim_prefix("$"),args)
			return localize(post,args),
		"compare" : func():
			var c = double_colon_split(post)
			var v = args
			var s = c[0].split(".")
			for k in s:
				if v == null:
					return post
				v = v.get(k)
			var compare
			if c[2] == "float":
				compare = c[3].to_float()
			elif c[2] == "int":
				compare = c[3].to_int()
			var r = false
			if c[1] == ">":
				r = v > compare
			elif c[1] == "<":
				r = v < compare
			elif c[1] == ">=":
				r = v >= compare
			elif c[1] == "<=":
				r = v <= compare
			var out = ""
			
			if c[4] == "out":
				out = c[5] if r else ""
			elif c[4] == "alt":
				out = c[5] if r else c[6]
			elif c[4] == "loc":
				out = localize(c[5],args) if r else ""
			elif c[4] == "altloc":
				out = localize(c[5],args) if r else localize(c[6],args)
			return out,
		"genderswitch" : func():
			var x = double_colon_split(post)
			var v = x[0]
			if x.size() == 3: 
				v = Global.get_character("player").gender_id
				x.push_front(null)
			elif v.begins_with("$"): 
				v = Global.recursive_get(v.trim_prefix("$"),args)
				if v is String: v = Global.get_character(v)
			else: v = Global.get_character(v).gender_id
			var g = Global.get_gender_value(v)
			return x[1] if g == Global.GENDER_NEUTRAL else x[2] if g == Global.GENDER_FEM else x[3],
		"currentdate" : func():
			return Global.current_time().date_loc(),
		"inputkey" : func():
			var arr = InputMap.action_get_events(post)
			if arr is Array and !arr.is_empty():
				var keys = []
				var mbutton = []
				var cbutton = []
				var joystick = []
				for i in arr:
					if i is InputEventKey:
						keys.append(i)
					elif i is InputEventMouseButton:
						mbutton.append(i)
					elif i is InputEventJoypadButton:
						cbutton = i
				if !keys.is_empty():
					return OS.get_keycode_string(keys[0].get_physical_keycode_with_modifiers())
			return " ",
		"express" : func():
			var s = double_colon_split(post)
			return "%s" % Global.express(s[0],s[1].split(","),args),
		"ifv" : func():
			var s = double_colon_split(post)
			var r = Global.recursive_get(s[0],args) == s[1]
			return (Global.localize(s[2].trim_prefix("l!"),args) if s[2].begins_with("l!") else s[2]) if r else (Global.localize(s[3].trim_prefix("l!"),args) if s[3].begins_with("l!") else s[3]) if s.size() == 4 else ""
	}
	return f.get(pre,func():
			pass).call()
