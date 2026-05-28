class_name ItemData
extends Resource
## 物品数据模型


enum ItemType { PILL, MATERIAL, TREASURE, EQUIPMENT, TECHNIQUE_BOOK, RECIPE }

@export var item_name: String = ""
@export var item_type: int = ItemType.MATERIAL
@export var quality: int = 0  # 0=废, 1=下, 2=中, 3=上, 4=极品
@export var quantity: int = 1
@export var description: String = ""
@export var effects: Dictionary = {}  # 丹药效果/装备加成


func get_quality_name() -> String:
	match quality:
		0: return "废品"
		1: return "下品"
		2: return "中品"
		3: return "上品"
		4: return "极品"
	return "未知"
