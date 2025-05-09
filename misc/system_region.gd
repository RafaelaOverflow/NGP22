extends Resource
class_name SystemRegion

@export var start := 1000.0
@export var limit := 10000.0
@export var sub_regions : Array[SystemRegion] = []
func get_sub_region_from_pos(pos) -> SystemRegion:
	for s : SystemRegion in sub_regions:
		if pos >= s.start and pos <= s.limit: return s
	return null
func get_sub_region_by_tag(tag):
	for s : SystemRegion in sub_regions:
		if tag in s.tags: return s
	return null
@export var tags : Array[StringName] = []

func get_random_position(random):
	return random.randf_range(start,limit)
