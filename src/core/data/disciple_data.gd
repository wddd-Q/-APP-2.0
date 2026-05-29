class_name DiscipleData
extends Resource
## 弟子数据模型


## 属性
@export var disciple_id: String = ""
@export var disciple_name: String = ""
@export var gender: int = 0  # 0=男, 1=女
@export var age: int = 18
@export var lifespan: int = 120
@export var alive: bool = true

## 六维属性 (0-100)
@export var bone_structure: int = 50    # 根骨 — 影响突破
@export var comprehension: int = 50     # 悟性 — 影响领悟功法
@export var fortune: int = 50           # 福缘 — 影响奇遇
@export var mentality: int = 50         # 心性 — 抵抗心魔
@export var charm: int = 50             # 魅力 — 外交/弟子关系
@export var talent: int = 50            # 资质 — 修炼速度

## 灵根
@export var spirit_root_quality: String = "true"  # heaven/variant/true/false/waste
@export var spirit_elements: Array = []  # [0=金, 1=木, 2=水, 3=火, 4=土]

## 修炼
@export var realm: int = 1       # 1-9 (当前大境界)
@export var sub_realm: int = 1   # 当前小阶段
@export var cultivation_progress: float = 0.0  # 0.0-1.0
@export var breakthrough_attempts: int = 0  # 当前阶段的突破失败次数

## 技能
@export var skills: Dictionary = {
	"alchemy": 0,       # 炼丹
	"crafting": 0,      # 炼器
	"formation": 0,     # 阵法
	"beast_taming": 0,  # 御兽
	"talisman": 0,      # 符箓
	"medicine": 0,      # 医术
}

## 功法
@export var techniques: Array = []

## 装备
@export var equipment: Array = []

## 关系
@export var relationships: Array = []  # [{target_id, type, strength}]

## 人格标签 (叙事涌现状积木)
@export var personalities: Array = []  # ["勇猛", "谨慎", "贪婪", "忠诚", ...]
@export var specialty: String = ""  # 擅长方向，如炼丹、剑修、阵法
@export var origin_story: String = ""  # 入门前经历
@export var loyalty: int = 50  # 对宗门的归属感，影响叛逃/任事风险

## 当前状态
@export var assigned_task: String = ""  # cultivating/alchemy/exploring/guarding/idle
@export var position: String = "普通弟子"  # 职位
@export var location: String = "sect"    # sect/mission/exploring/dead
@export var injured: bool = false
@export var life_memories: Array = []  # 关键人生事件记录 ["宗门历25年 筑基成功", ...]


func add_memory(text: String) -> void:
	if text.is_empty():
		return
	life_memories.append(text)
	if life_memories.size() > 30:
		life_memories.pop_front()


func get_cultivation_multiplier() -> float:
	# 从 DataRegistry 查询灵根倍率（由 gameplay 层调用时通过 DataRegistry 获取）
	# Resource 层提供灵根品质字段，倍率查询由调用方负责
	return 1.0  # 默认值，实际乘法由 DiscipleController 使用 DataRegistry 计算


func get_years_to_next_breakthrough() -> int:
	return 10


func get_cultivation_speed() -> float:
	# 基础修炼速度，由调用方乘以各加成
	return talent / 50.0
