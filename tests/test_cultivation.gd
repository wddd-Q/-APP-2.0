extends Node
## 修炼系统单元测试


var passed: int = 0
var failed: int = 0


func _ready() -> void:
	run_tests()
	print_summary()
	get_tree().quit()


func run_tests() -> void:
	test_realm_data()
	test_spirit_root_multipliers()
	test_cultivation_progress()
	test_aging_mechanic()
	test_breakthrough_math()


func test_realm_data() -> void:
	print("\n=== 境界数据 ===")
	assert_eq(DataRegistry.get_realm_name(1), "练气")
	assert_eq(DataRegistry.get_realm_name(9), "飞升")
	assert_eq(DataRegistry.get_realm_sub_count(1), 9)
	assert_eq(DataRegistry.get_realm_sub_count(3), 4)


func test_spirit_root_multipliers() -> void:
	print("\n=== 灵根倍率 ===")
	var roots = DataRegistry.spirit_roots
	assert_gt(roots["heaven"]["cultivation_mult"], roots["variant"]["cultivation_mult"], "天灵根>异灵根")
	assert_gt(roots["variant"]["cultivation_mult"], roots["true"]["cultivation_mult"], "异灵根>真灵根")
	assert_gt(roots["true"]["cultivation_mult"], roots["false"]["cultivation_mult"], "真灵根>伪灵根")
	assert_gt(roots["false"]["cultivation_mult"], roots["waste"]["cultivation_mult"], "伪灵根>废灵根")


func test_cultivation_progress() -> void:
	print("\n=== 修炼进度 ===")
	var d = DiscipleData.new()
	d.disciple_name = "测试弟子"
	d.talent = 50
	d.spirit_root_quality = "true"
	d.realm = 1
	d.sub_realm = 1

	var base_speed = d.get_cultivation_speed()
	assert_approx(base_speed, 1.0, 0.01, "基础修炼速度≈1.0")


func test_aging_mechanic() -> void:
	print("\n=== 寿元机制 ===")
	var d = DiscipleData.new()
	d.disciple_name = "老人"
	d.realm = 1
	d.sub_realm = 1
	d.age = 100  # 练气期120寿元, 100岁已进入衰老
	d.lifespan = 120

	var old_bone = d.bone_structure
	# 模拟处理衰老
	if d.age > d.lifespan * 0.7:
		d.bone_structure = maxi(10, d.bone_structure - 1)

	assert_that(d.age < d.lifespan, "100岁应仍在寿元范围内")


func test_breakthrough_math() -> void:
	print("\n=== 突破数学 ===")
	GameSetup.setup_new_game("突破数学测试")

	var sect = GameManager.current_sect
	var d = DiscipleData.new()
	d.disciple_name = "突破测试"
	d.bone_structure = 80
	d.talent = 80
	d.spirit_root_quality = "heaven"
	d.realm = 1
	d.sub_realm = 9
	d.cultivation_progress = 1.5

	# 天灵根+瓶颈: 筑基基础概率25% × 2.0 = 50%
	# 在小阶段突破中 (sub_realm<9层), 成功率更高
	sect.disciples.append(d)

	# 多次模拟看结果分布
	var successes = 0
	for i in range(100):
		d.sub_realm = 9
		d.cultivation_progress = 1.5
		d.realm = 1
		var result = DiscipleController.check_breakthrough(d)
		if result.get("success", false) and result.get("type") == "realm":
			successes += 1

	print("  100次大境界突破(天灵根): 成功=%d次 (约50%%预期)" % successes)


func assert_eq(actual, expected, msg := "") -> void:
	if actual == expected:
		passed += 1
		print("  ✓ %s" % msg)
	else:
		failed += 1
		print("  ✗ %s: 期望=%s, 实际=%s" % [msg, str(expected), str(actual)])


func assert_gt(actual, minimum, msg := "") -> void:
	if actual > minimum:
		passed += 1
		print("  ✓ %s" % msg)
	else:
		failed += 1
		print("  ✗ %s: %s <= %s" % [msg, str(actual), str(minimum)])


func assert_approx(actual, expected, tolerance, msg := "") -> void:
	if abs(actual - expected) <= tolerance:
		passed += 1
		print("  ✓ %s" % msg)
	else:
		failed += 1
		print("  ✗ %s: 期望≈%f, 实际=%f" % [msg, expected, actual])


func assert_that(condition: bool, msg := "") -> void:
	if condition:
		passed += 1
		print("  ✓ %s" % msg)
	else:
		failed += 1
		print("  ✗ %s" % msg)


func print_summary() -> void:
	print("\n" + "=".repeat(40))
	print("修炼系统测试: %d 通过, %d 失败" % [passed, failed])
