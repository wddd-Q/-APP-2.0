extends Node
## 时间控制器 — 订阅 TimeManager 信号，驱动每月/每年结算


func _ready() -> void:
	EventBus.month_passed.connect(_on_month_passed)
	EventBus.year_passed.connect(_on_year_passed)


func _on_month_passed(month: int, year: int) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	# 0. 设施修建/翻修进度
	SectController.process_construction()

	# 1. 弟子修炼
	_process_all_cultivation(sect)

	# 2. 资源产出
	_process_resources(sect)

	# 2.5. 设施效果（医馆治疗、灵兽园产出等）
	_process_facility_effects(sect)

	# 3. 维护费
	_process_maintenance(sect)

	# 3.5. 职位俸禄
	SectController.process_all_salaries()

	# 4. 弟子关系自然变化
	_process_relationships(sect)

	# 5. 任务月度消耗（炼丹/炼器月费）
	_process_task_costs(sect)

	# 6. 宗门晋升检查
	SectController.check_rank_promotion()

	# 7. 副本进度推进
	DungeonController.process_monthly()

	# 8. 随机事件
	EventController.roll_events()


func _on_year_passed(year: int) -> void:
	var sect = GameManager.current_sect
	if not sect:
		return

	# 年度结算
	_process_aging(sect)
	WorldController.process_npc_turn()


func _process_all_cultivation(sect: Resource) -> void:
	for disciple in sect.disciples:
		if not disciple.alive:
			continue
		if disciple.assigned_task == "cultivating" or disciple.assigned_task == "":
			var gained = DiscipleController.process_cultivation(disciple)

			# 自动检查突破
			if disciple.cultivation_progress >= 1.0:
				DiscipleController.check_breakthrough(disciple)


func _process_resources(sect: Resource) -> void:
	var vein = sect.get_facility("spirit_vein")
	if vein:
		var output = DataRegistry.facility_templates.get("spirit_vein", {}).get("stone_output", {}).get(vein.level, 0)
		sect.add_spirit_stones(output)

	var field = sect.get_facility("spirit_field")
	if field:
		var output = DataRegistry.facility_templates.get("spirit_field", {}).get("herb_output", {}).get(field.level, 0)
		sect.add_resource(sect.herbs, "spirit_herb", output)


func _process_facility_effects(sect: Resource) -> void:
	# 医馆：每月恢复受伤弟子的修为进度
	var medical = sect.get_facility("medical_hall")
	if medical:
		var heal_rate = DataRegistry.facility_templates["medical_hall"]["heal_rate"][medical.level]
		for d in sect.disciples:
			if d.alive and d.cultivation_progress < 0.0:
				d.cultivation_progress = minf(1.0, d.cultivation_progress + heal_rate)

	# 灵兽园：每月产出兽材
	var beast_garden = sect.get_facility("spirit_beast_garden")
	if beast_garden:
		var lv = beast_garden.level
		if randf() < 0.3 + lv * 0.1:
			var mat = ["beast_fur", "beast_bone", "beast_blood"][randi() % 3]
			var qty = lv + randi() % (lv + 1)
			sect.add_resource(sect.beast_materials, mat, qty)

	# 阵法殿：每月概率发现新副本
	var formation = sect.get_facility("formation_hall")
	if formation:
		if randf() < 0.05 * formation.level:
			var undiscovered: Array[String] = []
			for did in DungeonController.dungeon_instances:
				var dg: DungeonData = DungeonController.dungeon_instances[did]
				if not dg.is_discovered:
					undiscovered.append(did)
			if not undiscovered.is_empty():
				var pick = undiscovered[randi() % undiscovered.size()]
				DungeonController.discover_dungeon(pick)


func _process_maintenance(sect: Resource) -> void:
	var total = 0
	for facility in sect.facilities:
		var maint = DataRegistry.facility_templates.get(facility.facility_type, {}).get("maintenance", {}).get(facility.level, 0)
		total += maint

	if total > 0:
		sect.spend_spirit_stones(total)
		# 如果灵石不够维护，设施可能降级或停机（未来实现）


func _process_task_costs(sect: Resource) -> void:
	var total_cost = 0
	var total_income = 0
	for d in sect.disciples:
		if not d.alive:
			continue
		# 每月持续消耗型任务（炼丹/炼器）
		var cost = DiscipleController.TASK_COSTS.get(d.assigned_task, 0)
		if d.assigned_task in ["alchemy", "crafting"] and cost > 0:
			if sect.spend_spirit_stones(cost):
				total_cost += cost
		# 打工任务：每月产出灵石
		if d.assigned_task in DiscipleController.WORK_INCOME:
			var income = DiscipleController.get_work_income(d, d.assigned_task)
			sect.add_spirit_stones(income)
			total_income += income
			# 风险：受伤
			var info = DiscipleController.WORK_INCOME[d.assigned_task]
			if randf() < info["risk"]:
				d.cultivation_progress = maxf(0.0, d.cultivation_progress - 0.15)
			# 采集灵草额外获得材料
			if d.assigned_task == "herb_gathering" and randf() < 0.4:
				var herb_qty = 1 + randi() % 3
				sect.add_resource(sect.herbs, "spirit_herb", herb_qty)
	if total_cost > 0:
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, -total_cost)
	if total_income > 0:
		EventBus.spirit_stones_changed.emit(sect.spirit_stones, total_income)


func _process_relationships(sect: Resource) -> void:
	for d in sect.disciples:
		if not d.alive:
			continue
		for rel in d.relationships:
			var strength = rel.get("strength", 0)
			if strength > 0:
				rel["strength"] = maxi(-100, strength - 1)  # 自然衰减
			elif strength < 0:
				rel["strength"] = mini(100, strength + 1)  # 仇恨随时间淡化


func _process_aging(sect: Resource) -> void:
	for disciple in sect.disciples:
		if not disciple.alive:
			continue
		disciple.age += 1

		# 医馆寿元延长
		var medical = sect.get_facility("medical_hall")
		var life_ext = 0
		if medical:
			life_ext = DataRegistry.facility_templates.get("medical_hall", {}).get("life_extension", {}).get(medical.level, 0)

		# 寿元检查
		if disciple.age >= disciple.lifespan + life_ext:
			disciple.alive = false
			disciple.add_memory("宗门历%d年 寿尽坐化。" % TimeManager.year)
			EventBus.disciple_died.emit(disciple.disciple_id, "寿尽坐化")

		# 衰老效果
		var realm_data = DataRegistry.cultivation_realms.get(disciple.realm, {})
		var lifespan = realm_data.get("lifespan", 120)
		if disciple.age > lifespan * 0.7:
			disciple.talent = maxi(10, disciple.talent - 1)
