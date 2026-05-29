extends Node
## 炼丹炼器控制器

const PillRecipeData = preload("res://src/core/data/pill_recipe_data.gd")
const DiscipleData = preload("res://src/core/data/disciple_data.gd")
const CraftRecipeData = preload("res://src/core/data/craft_recipe_data.gd")
const ItemData = preload("res://src/core/data/item_data.gd")


func craft_pill(recipe: PillRecipeData, alchemist: DiscipleData) -> Dictionary:
	var sect = GameManager.current_sect

	# 检查材料
	for material_id in recipe.materials:
		var required = recipe.materials[material_id]
		if sect.herbs.get(material_id, 0) < required:
			return {"success": false, "reason": "材料不足: " + material_id}

	# 消耗材料
	for material_id in recipe.materials:
		sect.herbs[material_id] -= recipe.materials[material_id]
		EventBus.herb_changed.emit(material_id, sect.herbs[material_id])

	# 计算成功率
	var success_rate = recipe.base_success_rate
	success_rate *= (alchemist.skills.get("alchemy", 0) + 50.0) / 100.0

	# 设施加成
	var alchemy_hall = sect.get_facility("alchemy_hall")
	if alchemy_hall:
		var bonus = DataRegistry.facility_templates.get("alchemy_hall", {}).get("alchemy_bonus", {}).get(alchemy_hall.level, 0.0)
		success_rate *= (1.0 + bonus)

	# 火种加成（默认凡火 +0%）
	# success_rate *= (1.0 + fire_bonus)

	var roll = randf()
	if roll > success_rate:
		# 炼制失败
		if roll > 0.99:  # 大失败
			return {"success": false, "reason": "炸炉！材料全毁", "material_lost": true}
		return {"success": false, "reason": "炼制失败"}

	# 判定品质 (与 ItemData 一致: 0=废品,1=下品,2=中品,3=上品,4=极品)
	var quality = 1  # 下品（最低成功品质）
	if roll < success_rate * 0.05:
		quality = 4  # 极品 (5%)
	elif roll < success_rate * 0.20:
		quality = 3  # 上品 (15%)
	elif roll < success_rate * 0.50:
		quality = 2  # 中品 (30%)
	# 其余为下品(1)

	# 提升技能
	alchemist.skills["alchemy"] = mini(100, alchemist.skills["alchemy"] + 1)
	sect.add_inventory_item(recipe.result_item, recipe.recipe_name, ItemData.ItemType.PILL, quality, 1, {
		"category": "pill",
		"source": "alchemy",
	})
	alchemist.add_memory("宗门历%d年 炼成%s%s。" % [
		TimeManager.year,
		_get_quality_name(quality),
		recipe.recipe_name,
	])

	EventBus.pill_crafted.emit(recipe.result_item, quality, alchemist.disciple_id)
	return {
		"success": true,
		"pill_id": recipe.result_item,
		"quality": quality,
		"quality_name": _get_quality_name(quality),
	}


func forge_equipment(recipe: CraftRecipeData, crafter: DiscipleData) -> Dictionary:
	var sect = GameManager.current_sect

	for material_id in recipe.materials:
		var required = recipe.materials[material_id]
		if sect.ores.get(material_id, 0) < required:
			return {"success": false, "reason": "材料不足: " + material_id}

	for material_id in recipe.materials:
		sect.ores[material_id] -= recipe.materials[material_id]
		EventBus.ore_changed.emit(material_id, sect.ores[material_id])

	var success_rate = recipe.base_success_rate
	success_rate *= (crafter.skills.get("crafting", 0) + 50.0) / 100.0

	# 炼器坊加成
	var craft_hall = sect.get_facility("alchemy_hall")
	if craft_hall:
		var bonus = DataRegistry.facility_templates.get("alchemy_hall", {}).get("alchemy_bonus", {}).get(craft_hall.level, 0.0)
		success_rate *= (1.0 + bonus)

	var roll = randf()
	if roll > success_rate:
		return {"success": false, "reason": "炼制失败"}

	# 品质 (与 ItemData 一致: 0=废品,1=下品,2=中品,3=上品,4=极品)
	var quality = 1
	if roll < success_rate * 0.05:
		quality = 4
	elif roll < success_rate * 0.20:
		quality = 3
	elif roll < success_rate * 0.50:
		quality = 2

	crafter.skills["crafting"] = mini(100, crafter.skills["crafting"] + 1)
	sect.add_inventory_item(recipe.result_item, recipe.recipe_name, ItemData.ItemType.EQUIPMENT, quality, 1, {
		"category": "equipment",
		"source": "forge",
	})
	crafter.add_memory("宗门历%d年 炼成%s%s。" % [
		TimeManager.year,
		_get_quality_name(quality),
		recipe.recipe_name,
	])

	EventBus.equipment_forged.emit(recipe.result_item, quality, crafter.disciple_id)
	return {"success": true, "equipment_id": recipe.result_item, "quality": quality}


func _get_quality_name(quality: int) -> String:
	match quality:
		0: return "废品"
		1: return "下品"
		2: return "中品"
		3: return "上品"
		4: return "极品"
	return "未知"
