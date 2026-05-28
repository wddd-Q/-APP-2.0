class_name CraftRecipeData
extends Resource
## 器方数据模型


@export var recipe_name: String = ""
@export var result_item: String = ""  # 产出法器ID
@export var materials: Dictionary = {}
@export var difficulty: int = 1
@export var base_success_rate: float = 0.4
@export var craft_time_months: int = 2
