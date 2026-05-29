extends Node
## 新游戏初始化

const FacilityData = preload("res://src/core/data/facility_data.gd")
const DiscipleData = preload("res://src/core/data/disciple_data.gd")


static func setup_new_game(sect_name: String) -> void:
	GameManager.start_new_game(sect_name)
	var sect = GameManager.current_sect

	# 1. 初始资源
	sect.spirit_stones = 300
	sect.herbs["spirit_herb"] = 20
	sect.ores["iron"] = 10

	# 2. 初始设施: 修炼室 Lv.1 + 灵脉 Lv.1
	var chamber = FacilityData.new()
	chamber.facility_type = "cultivation_chamber"
	chamber.level = 1
	sect.facilities.append(chamber)

	var vein = FacilityData.new()
	vein.facility_type = "spirit_vein"
	vein.level = 1
	sect.facilities.append(vein)

	# 3. 初始弟子: 3位各具特色的弟子
	_create_starter_disciple(sect, "大弟子", 0, 65, 55, 45, 60, 40, 55, "true", [0, 1, 2], ["勇猛", "忠诚"])
	_create_starter_disciple(sect, "二弟子", 1, 40, 70, 60, 50, 65, 45, "variant", [1, 3], ["好奇", "孤傲"])
	_create_starter_disciple(sect, "小师妹", 1, 50, 50, 80, 45, 55, 60, "true", [2, 3, 4], ["善良", "谨慎"])

	# 4. 初始职位（新宗门暂由掌门直接管理，不设高阶职位）

	# 5. 预设一个练气后期的弟子（让玩家很快体验到突破）
	var senior = sect.disciples[0]
	senior.realm = 1
	senior.sub_realm = 8  # 练气八层
	senior.cultivation_progress = 0.8  # 快满了

	# 5. 初始门规: 无

	EventBus.game_started.emit()


static func _create_starter_disciple(sect: Resource, dname: String, gender: int,
		bone: int, comp: int, fortune: int, mental: int, charm: int, talent: int,
		root_quality: String, elements: Array, personalities: Array = []) -> void:

	var d = DiscipleData.new()
	d.disciple_name = dname
	d.gender = gender
	d.age = 22 if gender == 0 else 19
	d.bone_structure = bone
	d.comprehension = comp
	d.fortune = fortune
	d.mentality = mental
	d.charm = charm
	d.talent = talent
	d.spirit_root_quality = root_quality
	d.spirit_elements = elements
	d.realm = 1
	d.sub_realm = 1
	d.cultivation_progress = 0.0
	d.assigned_task = "cultivating"
	d.lifespan = 120
	d.personalities = personalities
	d.specialty = _starter_specialty(dname)
	d.origin_story = _starter_story(dname)

	sect.add_disciple(d)
	d.add_memory("宗门历%d年 %s入门，成为本门初代弟子。" % [TimeManager.year, d.disciple_name])


static func _starter_specialty(dname: String) -> String:
	match dname:
		"大弟子":
			return "护山与剑修"
		"二弟子":
			return "阵法与探秘"
		"小师妹":
			return "灵植与医术"
		_:
			return "宗门杂务"


static func _starter_story(dname: String) -> String:
	match dname:
		"大弟子":
			return "山门破败时最早留下的弟子，曾独自守过一夜妖兽袭山，因此行事偏向勇猛直接。"
		"二弟子":
			return "幼年在旧书摊翻到残缺阵图，对失传阵纹格外敏感，常怀疑本门山门另有旧秘。"
		"小师妹":
			return "由山下药户送入宗门，自小识得草木药性，待人温和，却也比旁人更能察觉伤病与心绪。"
		_:
			return "随掌门重整山门的初代弟子。"
