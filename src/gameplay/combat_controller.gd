extends Node
## 战斗控制器

const FactionData = preload("res://src/core/data/faction_data.gd")
const DiscipleData = preload("res://src/core/data/disciple_data.gd")
const CombatResult = preload("res://src/core/data/combat_result.gd")


func simulate_battle(attacker_id: String, defender_id: String, attacker_sect: FactionData, defender_sect: FactionData) -> CombatResult:
	var attacker_power = _calculate_faction_power(attacker_sect)
	var defender_power = _calculate_faction_power(defender_sect)

	# 防守方有地形+护山大阵加成
	if defender_id != "wild_beast":  # 非妖兽
		defender_power = int(defender_power * 1.3)
	var power_ratio = float(attacker_power) / maxi(defender_power, 1)

	var result = CombatResult.new()
	result.attacker_id = attacker_id
	result.defender_id = defender_id
	result.attacker_power = attacker_power
	result.defender_power = defender_power
	result.power_ratio = power_ratio

	if power_ratio >= 1.0:
		result.attacker_won = true
		result.loot_spirit_stones = _calculate_loot(defender_sect)
		result.battle_description = _generate_description(power_ratio, true)
	else:
		result.attacker_won = false
		result.loot_spirit_stones = 0
		result.battle_description = _generate_description(power_ratio, false)

	# 计算伤亡
	var casualty_rate = _get_casualty_rate(power_ratio, result.attacker_won)
	result.attacker_losses = int(attacker_sect.combat_power * casualty_rate * 0.01)
	result.defender_losses = int(defender_sect.combat_power * casualty_rate * 0.01)

	# 更新宗门状态
	if result.attacker_won:
		attacker_sect.prestige += 300
		defender_sect.prestige -= 200
		defender_sect.spirit_stones -= result.loot_spirit_stones
	else:
		attacker_sect.prestige -= 100
		defender_sect.prestige += 200

	EventBus.combat_finished.emit(result)
	return result


func _calculate_faction_power(sect: FactionData) -> int:
	return sect.combat_power


func calculate_disciple_combat_power(disciple: DiscipleData) -> int:
	var realm_power = DataRegistry.cultivation_realms.get(disciple.realm, {}).get("combat_power_base", 10)
	var power = realm_power * (disciple.bone_structure / 50.0)

	# 演武场加成
	var sect = GameManager.current_sect
	var arena = sect.get_facility("arena") if sect else null
	if arena:
		var arena_bonus = DataRegistry.facility_templates.get("arena", {}).get("combat_bonus", {}).get(arena.level, 0.0)
		power *= (1.0 + arena_bonus)

	# 功法加成
	power *= DiscipleController.get_technique_cultivation_bonus(disciple)

	# 装备加成
	power *= DiscipleController.get_equipment_combat_bonus(disciple)

	return int(power)


func _get_casualty_rate(power_ratio: float, attacker_won: bool) -> float:
	if attacker_won:
		if power_ratio > 2.0: return 5.0
		elif power_ratio > 1.5: return 15.0
		else: return 30.0
	else:
		if power_ratio > 0.7: return 50.0
		elif power_ratio > 0.5: return 65.0
		else: return 80.0


func _calculate_loot(defender_sect: FactionData) -> int:
	return int(defender_sect.spirit_stones * 0.3)  # 掠夺30%灵石


func _generate_description(power_ratio: float, won: bool) -> String:
	if won:
		if power_ratio > 2.0:
			return "我方以碾压之势击溃敌军，几乎无伤。"
		elif power_ratio > 1.5:
			return "经过一番激战，我方取得优势胜利。"
		else:
			return "惨胜如败，虽然赢了但伤亡惨重。"
	else:
		if power_ratio > 0.7:
			return "惜败于敌，撤回宗门重整旗鼓。"
		else:
			return "大败而归，宗门元气大伤。"
