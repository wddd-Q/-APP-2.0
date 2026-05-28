extends Node
## 存档管理器

const SectData = preload("res://src/core/data/sect_data.gd")
const FacilityData = preload("res://src/core/data/facility_data.gd")
const DiscipleData = preload("res://src/core/data/disciple_data.gd")
const ItemData = preload("res://src/core/data/item_data.gd")


const SAVE_DIR := "user://saves/"
const SAVE_EXT := ".json"
const SAVE_VERSION := "0.1.0"


func _ready() -> void:
	_ensure_save_dir()


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot_name: String, sect_data: Resource) -> bool:
	if sect_data == null:
		return false

	var data = _serialize_sect(sect_data)
	data["version"] = SAVE_VERSION
	data["timestamp"] = Time.get_unix_time_from_system()

	var path = SAVE_DIR + slot_name + SAVE_EXT
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_game(path: String) -> Resource:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null:
		return null

	var version = json.get("version", "")
	if version != SAVE_VERSION:
		push_warning("存档版本不匹配: %s vs %s" % [version, SAVE_VERSION])

	return _deserialize_sect(json)


func get_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return slots

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(SAVE_EXT):
			var path = SAVE_DIR + file_name
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var data = JSON.parse_string(file.get_as_text())
				file.close()
				if data:
					slots.append({
						"name": file_name.trim_suffix(SAVE_EXT),
						"date": data.get("date_string", "未知"),
						"sect_name": data.get("name", "未知宗门"),
						"path": path,
					})
		file_name = dir.get_next()

	return slots


## === 序列化 ===

func _serialize_sect(sect: Resource) -> Dictionary:
	var data: Dictionary = {}
	data["name"] = sect.get("name")
	data["rank"] = sect.get("rank")
	data["prestige"] = sect.get("prestige")
	data["spirit_stones"] = sect.get("spirit_stones")
	data["karma"] = sect.get("karma")
	data["date_string"] = TimeManager.get_date_string()
	data["year"] = TimeManager.year
	data["month"] = TimeManager.month

	# 二级资源
	data["herbs"] = _dict_to_var(sect.get("herbs"))
	data["ores"] = _dict_to_var(sect.get("ores"))
	data["beast_materials"] = _dict_to_var(sect.get("beast_materials"))
	data["rare_materials"] = _dict_to_var(sect.get("rare_materials"))

	# 设施
	data["facilities"] = []
	for f in sect.get("facilities"):
		data["facilities"].append({
			"type": f.facility_type,
			"level": f.level,
			"is_building": f.is_building,
			"build_progress": f.build_progress,
		})

	# 弟子
	data["disciples"] = []
	for d in sect.get("disciples"):
		var dd = {
			"name": d.disciple_name,
			"gender": d.gender,
			"age": d.age,
			"lifespan": d.lifespan,
			"alive": d.alive,
			"bone": d.bone_structure,
			"comprehension": d.comprehension,
			"fortune": d.fortune,
			"mentality": d.mentality,
			"charm": d.charm,
			"talent": d.talent,
			"root_quality": d.spirit_root_quality,
			"elements": d.spirit_elements,
			"realm": d.realm,
			"sub_realm": d.sub_realm,
			"progress": d.cultivation_progress,
			"attempts": d.breakthrough_attempts,
			"skills": d.skills,
			"task": d.assigned_task,
			"location": d.location,
			"personalities": d.personalities,
		}
		data["disciples"].append(dd)

	# 物品
	data["inventory"] = []
	for item in sect.get("inventory"):
		data["inventory"].append({
			"name": item.item_name,
			"type": item.item_type,
			"quality": item.quality,
			"quantity": item.quantity,
		})

	# 外交关系
	data["faction_relations"] = sect.get("faction_relations")

	# 门规
	data["active_decrees"] = sect.get("active_decrees")

	# 事件状态
	data["event_history"] = EventController.event_history
	data["event_chain_state"] = EventController.event_chain_state

	return data


## === 反序列化 ===

func _deserialize_sect(data: Dictionary) -> Resource:
	var sect = SectData.new()
	sect.name = data.get("name", "未知宗门")
	sect.rank = data.get("rank", 9)
	sect.prestige = data.get("prestige", 0)
	sect.spirit_stones = data.get("spirit_stones", 0)
	sect.karma = data.get("karma", 0)

	# 恢复时间
	if data.has("year") and data.has("month"):
		TimeManager.year = data["year"]
		TimeManager.month = data["month"]

	# 二级资源
	sect.herbs = data.get("herbs", {})
	sect.ores = data.get("ores", {})
	sect.beast_materials = data.get("beast_materials", {})
	sect.rare_materials = data.get("rare_materials", {})

	# 设施
	for fd in data.get("facilities", []):
		var f = FacilityData.new()
		f.facility_type = fd["type"]
		f.level = fd["level"]
		f.is_building = fd.get("is_building", false)
		f.build_progress = fd.get("build_progress", 0)
		sect.facilities.append(f)

	# 弟子
	for dd in data.get("disciples", []):
		var d = DiscipleData.new()
		d.disciple_name = dd["name"]
		d.gender = dd["gender"]
		d.age = dd["age"]
		d.lifespan = dd["lifespan"]
		d.alive = dd["alive"]
		d.bone_structure = dd["bone"]
		d.comprehension = dd["comprehension"]
		d.fortune = dd["fortune"]
		d.mentality = dd["mentality"]
		d.charm = dd["charm"]
		d.talent = dd["talent"]
		d.spirit_root_quality = dd["root_quality"]
		d.spirit_elements = dd["elements"]
		d.realm = dd["realm"]
		d.sub_realm = dd["sub_realm"]
		d.cultivation_progress = dd["progress"]
		d.breakthrough_attempts = dd["attempts"]
		d.skills = dd.get("skills", {})
		d.assigned_task = dd.get("task", "")
		d.location = dd.get("location", "sect")
		d.personalities = dd.get("personalities", [])
		sect.disciples.append(d)

	# 物品
	for idata in data.get("inventory", []):
		var item = ItemData.new()
		item.item_name = idata["name"]
		item.item_type = idata["type"]
		item.quality = idata["quality"]
		item.quantity = idata["quantity"]
		sect.inventory.append(item)

	# 外交
	sect.faction_relations = data.get("faction_relations", {})

	# 门规
	sect.active_decrees = data.get("active_decrees", [])

	# 事件状态恢复
	EventController.event_history = data.get("event_history", [])
	EventController.event_chain_state = data.get("event_chain_state", {})

	return sect


func _dict_to_var(d: Dictionary) -> Dictionary:
	return d
