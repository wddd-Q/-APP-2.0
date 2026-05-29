class_name FacilityData
extends Resource
## 设施数据模型 — 纯数据，不含 autoload 依赖


@export var facility_type: String = ""  # cultivation_chamber, alchemy_hall, etc.
@export var level: int = 1
@export var is_building: bool = false
@export var build_progress: int = 0


func can_upgrade() -> bool:
	var max_level = _max_level()
	return level < max_level


func _max_level() -> int:
	var defaults = {
		"cultivation_chamber": 3, "alchemy_hall": 3, "scripture_pavilion": 3,
		"arena": 3, "formation_hall": 3, "spirit_beast_garden": 3, "crafting_hall": 3, "medical_hall": 3, "guest_quarters": 3,
		"spirit_field": 5, "spirit_vein": 5,
	}
	return defaults.get(facility_type, 3)
