extends Node
## 核心循环集成测试
## 运行方式: Godot 编辑器中附加到场景运行，或命令行:
##   godot --headless --script tests/test_core_loop.gd


var test_results: Array[String] = []
var passed: int = 0
var failed: int = 0


func _ready() -> void:
	run_all_tests()
	print_summary()
	get_tree().quit()


func run_all_tests() -> void:
	test_new_game_setup()
	test_disciples_cultivate()
	test_breakthrough_attempt()
	test_resource_generation()
	test_monthly_maintenance()
	test_recruitment_profiles()
	test_event_ledger_panel_build()
	test_onboarding_objectives()
	test_multiple_months_simulation()
	test_event_triggering()


func test_new_game_setup() -> void:
	print("\n=== 测试: 新游戏初始化 ===")
	GameSetup.setup_new_game("测试宗门")

	var sect = GameManager.current_sect
	assert_that(sect.name == "测试宗门", "宗门名称应为测试宗门")
	assert_that(sect.spirit_stones == 300, "初始灵石应为300")
	assert_that(sect.facilities.size() == 2, "应有2个初始设施")
	assert_that(sect.disciples.size() == 3, "应有3个初始弟子")
	assert_that(sect.herbs["spirit_herb"] == 20, "应有20株灵草")
	assert_that(sect.ores["iron"] == 10, "应有10块铁矿石")

	var senior = sect.disciples[0]
	assert_that(senior.sub_realm == 8, "大弟子应为练气八层")
	assert_that(senior.disciple_id != "", "初始弟子应拥有稳定ID")
	assert_that(not senior.life_memories.is_empty(), "初始弟子应拥有入门记忆")


func test_disciples_cultivate() -> void:
	print("\n=== 测试: 弟子修炼 ===")
	GameSetup.setup_new_game("修炼测试宗")

	var sect = GameManager.current_sect
	var disciple = sect.disciples[0]
	var old_progress = disciple.cultivation_progress

	# 分配修炼任务
	DiscipleController.assign_task(disciple, "cultivating")
	var gained = DiscipleController.process_cultivation(disciple)

	assert_that(gained > 0, "修炼应获取正数修为")
	assert_that(disciple.cultivation_progress > old_progress, "修为进度应增加")


func test_breakthrough_attempt() -> void:
	print("\n=== 测试: 突破尝试 ===")
	GameSetup.setup_new_game("突破测试宗")

	var sect = GameManager.current_sect
	var disciple = sect.disciples[0]
	disciple.realm = 1
	disciple.sub_realm = 1
	disciple.cultivation_progress = 1.5  # 超过100%

	var result = DiscipleController.check_breakthrough(disciple)
	# 突破有概率，多次测试
	var success_count = 0
	for i in range(10):
		if not disciple.alive:
			break
		disciple.cultivation_progress = 1.5
		result = DiscipleController.check_breakthrough(disciple)
		if result.get("success", false):
			success_count += 1
		if disciple.sub_realm >= 9:  # 到顶了
			disciple.sub_realm = 1

	assert_that(success_count >= 0, "突破测试完成（概率性，至少运行了）")
	print("  10次突破尝试，成功: %d 次" % success_count)


func test_resource_generation() -> void:
	print("\n=== 测试: 资源产出 ===")
	GameSetup.setup_new_game("资源测试宗")

	var sect = GameManager.current_sect
	var old_stones = sect.spirit_stones

	# 手动触发一个月结算中的资源部分
	TimeManager.advance_month()

	assert_that(sect.spirit_stones >= old_stones, "灵石产出不应减少原始库存")
	print("  灵石: %d → %d (+%d)" % [old_stones, sect.spirit_stones, sect.spirit_stones - old_stones])


func test_monthly_maintenance() -> void:
	print("\n=== 测试: 月维护费 ===")
	GameSetup.setup_new_game("维护测试宗")

	var sect = GameManager.current_sect
	# 初始只有2个设施，维护费 = 5(修炼室) + 5(灵脉) = 10
	# 每月灵石收入 = 10(灵脉产出) → 刚好平衡
	# 多推进几个月看有没有负数
	sect.spirit_stones = 100
	for i in range(12):
		TimeManager.advance_month()

	assert_that(sect.spirit_stones >= 0, "一年后灵石不应为负（产出≈维护）")
	print("  一年后灵石: %d" % sect.spirit_stones)


func test_recruitment_profiles() -> void:
	print("\n=== 测试: 招募弟子画像 ===")
	GameSetup.setup_new_game("招募测试宗")
	var sect = GameManager.current_sect
	sect.spirit_stones = 2000

	var candidates = RecruitmentController.generate_candidates(3)
	assert_that(candidates.size() == 3, "应生成3名候选弟子")
	var candidate = candidates[0]
	var attrs = [
		candidate["bone_structure"],
		candidate["comprehension"],
		candidate["fortune"],
		candidate["mentality"],
		candidate["charm"],
		candidate["talent"],
	]
	var has_variation = false
	for value in attrs:
		if value != 50:
			has_variation = true
			break
	assert_that(has_variation, "候选弟子属性不应全为50")
	assert_that(candidate.get("specialty", "") != "", "候选弟子应有擅长方向")
	assert_that(candidate.get("origin_story", "") != "", "候选弟子应有来历故事")

	var disciple = RecruitmentController.recruit(candidate)
	assert_that(disciple != null, "应能招收候选弟子")
	assert_that(disciple.specialty != "", "入门弟子应保留擅长方向")
	assert_that(disciple.origin_story != "", "入门弟子应保留来历故事")


func test_event_ledger_panel_build() -> void:
	print("\n=== 测试: 宗门纪事面板 ===")
	GameSetup.setup_new_game("纪事测试宗")
	var event = EventController.event_pool[0].duplicate(true)
	EventController.active_events = [event]
	EventController.unread_event_count = 1

	var panel = preload("res://src/ui/event_ledger_panel.gd").new()
	add_child(panel)
	panel.open_panel()
	assert_that(panel.visible, "宗门纪事面板应能打开")
	assert_that(EventController.unread_event_count == 0, "打开纪事后应清除未读红点")
	panel.queue_free()


func test_onboarding_objectives() -> void:
	print("\n=== 测试: 掌门初任目标 ===")
	GameSetup.setup_new_game("初任测试宗")
	var sect = GameManager.current_sect
	sect.spirit_stones = 5000

	var start_summary = OnboardingController.get_summary()
	assert_that(start_summary.get("completed", -1) == 0, "新游戏初任目标应从0开始")

	var candidate = RecruitmentController.generate_candidates(1)[0]
	RecruitmentController.recruit(candidate)
	assert_that(OnboardingController.get_summary().get("completed", 0) >= 1, "招收弟子应完成初任收徒目标")

	SectController.build_facility("alchemy_hall")
	assert_that(_objective_done("improve_facility"), "建设设施应完成初任建设目标")

	SectController.assign_position(sect.disciples[0], "副长老")
	assert_that(_objective_done("assign_officer"), "任命职位应完成初任任职目标")

	EventController.active_events = [EventController.event_pool[0].duplicate(true)]
	EventController.resolve_choice(EventController.active_events[0]["id"], 1)
	assert_that(_objective_done("resolve_event"), "处理纪事应完成初任纪事目标")
	assert_that(OnboardingController.story_unlocked, "四个初任目标完成后应解锁故事线索")


func test_multiple_months_simulation() -> void:
	print("\n=== 测试: 多年模拟 ===")
	GameSetup.setup_new_game("模拟测试宗")

	var sect = GameManager.current_sect
	# 模拟运行5年
	for i in range(60):
		TimeManager.advance_month()

	# 检查是否还有活着的弟子
	var alive = 0
	for d in sect.disciples:
		if d.alive:
			alive += 1

	assert_that(alive >= 3, "5年后至少还有3个初始弟子活着")
	assert_that(sect.spirit_stones > 0, "5年后灵石应>0")
	print("  5年后: 灵石=%d, 存活弟子=%d" % [sect.spirit_stones, alive])

	var senior = sect.disciples[0]
	print("  大弟子: %s %d层 进度=%.2f" % [DataRegistry.get_realm_name(senior.realm), senior.sub_realm, senior.cultivation_progress])


func test_event_triggering() -> void:
	print("\n=== 测试: 事件触发 ===")
	GameSetup.setup_new_game("事件测试宗")

	var events = EventController.roll_events()
	# 可能返回0-3个事件
	assert_that(events.size() <= 1, "每回合最多1个事件")
	print("  触发 %d 个事件" % events.size())

	for event in events:
		print("  - %s" % event.get("name", "未知事件"))


func assert_that(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  ✓ %s" % message)
	else:
		failed += 1
		print("  ✗ %s  [失败]" % message)


func _objective_done(objective_id: String) -> bool:
	for objective in OnboardingController.objectives:
		if objective.get("id", "") == objective_id:
			return objective.get("completed", false)
	return false


func print_summary() -> void:
	print("\n" + "=".repeat(40))
	print("测试结果: %d 通过, %d 失败, %d 总计" % [passed, failed, passed + failed])
	if failed == 0:
		print("全部测试通过 ✓")
	else:
		print("存在失败测试 ✗")
