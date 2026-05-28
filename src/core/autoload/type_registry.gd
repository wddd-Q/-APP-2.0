extends Node
## 类型注册表 — 预加载所有数据类，确保 class_name 在 autoload 加载前可用


const SectData = preload("res://src/core/data/sect_data.gd")
const DiscipleData = preload("res://src/core/data/disciple_data.gd")
const FacilityData = preload("res://src/core/data/facility_data.gd")
const ItemData = preload("res://src/core/data/item_data.gd")
const PillRecipeData = preload("res://src/core/data/pill_recipe_data.gd")
const CraftRecipeData = preload("res://src/core/data/craft_recipe_data.gd")
const FactionData = preload("res://src/core/data/faction_data.gd")
const CombatResult = preload("res://src/core/data/combat_result.gd")
const NameGenerator = preload("res://src/core/systems/name_generator.gd")
