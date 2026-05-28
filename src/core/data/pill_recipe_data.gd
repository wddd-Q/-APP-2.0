class_name PillRecipeData
extends Resource
## 丹方数据模型


@export var recipe_name: String = ""
@export var result_item: String = ""  # 产出丹药ID
@export var materials: Dictionary = {}  # {材料ID: 数量}
@export var difficulty: int = 1  # 炼制难度 (DC)
@export var base_success_rate: float = 0.5
@export var craft_time_months: int = 1
