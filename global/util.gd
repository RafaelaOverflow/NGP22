extends Node
class_name Util

static func get_face_normal(dir):
	var a = abs(dir)
	if a.x > a.y:
		if a.x > a.z:
			if dir.x > 0.0: return Vector3(1,0,0)
			else: return Vector3(-1,0,0)
		else:
			if dir.z > 0.0: return Vector3(0,0,1)
			else: return Vector3(0,0,-1)
	else:
		if a.y > a.z:
			if dir.y > 0.0: return Vector3(0,1,0)
			else: return Vector3(0,-1,0)
		else:
			if dir.z > 0.0: return Vector3(0,0,1)
			else: return Vector3(0,0,-1)

static func sphere_pos_to_cube_pos(sphere_pos):
	return sphere_pos/vec3_max_abs(sphere_pos)

static func sphere_pos_to_tile_id(sphere_pos,tex_res):
	var cube_pos = sphere_pos_to_cube_pos(sphere_pos)
	var face_normal = get_face_normal(cube_pos)
	var i = PlanetData.normal_map.find(face_normal)
	var axisA := Vector3(face_normal.y, face_normal.z, face_normal.x)
	var axisB : Vector3 = face_normal.cross(axisA)
	var x = int(simplify_range(vec3_max(cube_pos * axisA),-1.0,1.0)*float(tex_res))
	var y = int(simplify_range(vec3_max(cube_pos * axisB),-1.0,1.0)*float(tex_res))
	#print("%s - %s - %s - %s - %s - %s - %s" % [cube_pos,face_normal,i,axisA,axisB,x,y])
	return Vector3i(min(x,tex_res-1),min(y,tex_res-1),i)

static func vec3_max(vec3):
	var a = abs(vec3)
	if a.x > a.y:
		if a.x > a.z:
			return vec3.x
		else:
			return vec3.z
	else:
		if a.y > a.z:
			return vec3.y
		else:
			return vec3.z

static func vec3_max_abs(vec3):
	return max(abs(vec3.x),abs(vec3.y),abs(vec3.z))


static func simplify_range(x,omin,omax):
	var diff = (omax - omin)
	return (x - omin)/diff

static func delta_load_dict(base : Dictionary, delta : Dictionary,D_NAME = "") -> Dictionary:
	if delta.has("!MINUS!"):
		for key in delta["!MINUS!"]:
			base.erase(key)
		delta.erase("!MINUS!")
	for key in delta.keys():
		if base.has(key):
			if typeof(base[key]) == typeof(delta[key]):
				if typeof(base[key]) == TYPE_DICTIONARY:
					delta_load_dict(base[key],delta[key],key)
				elif typeof(base[key]) == TYPE_ARRAY:
						base[key] = delta[key]
				else:
					if base[key] != delta[key]:
						base[key] = delta[key]
			else: base[key] = delta[key]
		else: base[key] = delta[key]
	
	return base

static func vec4i_xyz(vec4 : Vector4i) -> Vector3i:
	return Vector3i(vec4.x,vec4.y,vec4.z)

static func vec3w(vec3,w) -> Vector4i:
	return Vector4i(vec3.x,vec3.y,vec3.z,w)

static func clean_children(node:Node) -> void:
	for child :Node in node.get_children():
		node.remove_child(child)
		child.propagate_call("queue_free")
