class_name NameGenerator
extends Node
## 修仙风格名字生成器


static var surnames = [
	"李", "王", "张", "刘", "陈", "杨", "赵", "黄", "周", "吴",
	"徐", "孙", "马", "朱", "胡", "郭", "何", "高", "林", "罗",
	"郑", "梁", "谢", "宋", "唐", "韩", "曹", "许", "邓", "萧",
	"冯", "曾", "程", "蔡", "彭", "潘", "袁", "于", "董", "余",
	"苏", "叶", "吕", "魏", "蒋", "田", "杜", "丁", "沈", "姜",
	"慕容", "欧阳", "上官", "独孤", "南宫", "司徒", "司马", "西门",
]

static var male_given = [
	"天", "云", "风", "辰", "逸", "轩", "浩", "宇", "玄", "青",
	"剑", "白", "墨", "尘", "枫", "凌", "羽", "渊", "乾", "坤",
	"无极", "长生", "逍遥", "破天", "问道", "求仙", "长生", "不灭",
]

static var female_given = [
	"雪", "月", "瑶", "诗", "晴", "清", "灵", "若", "紫", "霜",
	"蝶", "烟", "兰", "碧", "柔", "萱", "婉", "静", "素", "荷",
	"仙儿", "灵儿", "梦瑶", "清雪", "紫烟", "碧落", "如月", "云裳",
]


static func generate_name(gender: int = -1) -> String:
	if gender == -1:
		gender = randi() % 2
	var surname = surnames[randi() % surnames.size()]
	var given_pool = male_given if gender == 0 else female_given
	var given = given_pool[randi() % given_pool.size()]
	return surname + given


static func generate_title(realm: int) -> String:
	var titles = {
		1: "修士",
		2: "真人",
		3: "上人",
		4: "真君",
		5: "道君",
		6: "天尊",
		7: "圣尊",
		8: "仙尊",
	}
	var title = titles.get(realm, "真人")
	if realm >= 3:
		title = "上人" if randf() < 0.5 else "真人"
	if realm >= 5:
		title = "道君" if randf() < 0.5 else "天尊"
	return title
