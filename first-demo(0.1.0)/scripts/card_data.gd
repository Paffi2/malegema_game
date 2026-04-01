extends RefCounted
class_name CardData

const MATERIALS := [
	# 与原项目一致的材质枚举，后续结算和升级会依赖该顺序。
    # "骨",
    # "黄玉",
    # "蓝宝石",
    # "石榴石",
    # "红宝石",
    # "玉",
    # "翡翠",
    # "石英",
    # "黑曜石"
	"bone",
	"topaz",
	"sapphire",
	"garnet",
	"ruby",
	"jade",
	"emerald",
	"quartz",
	"obsidian",
]

const BAMS := [
	{"cardId": "bam1", "suit": "bam", "rank": "1", "colors": ["g"], "points": 1},
	{"cardId": "bam2", "suit": "bam", "rank": "2", "colors": ["g"], "points": 1},
	{"cardId": "bam3", "suit": "bam", "rank": "3", "colors": ["g"], "points": 1},
	{"cardId": "bam4", "suit": "bam", "rank": "4", "colors": ["g"], "points": 1},
	{"cardId": "bam5", "suit": "bam", "rank": "5", "colors": ["g"], "points": 1},
	{"cardId": "bam6", "suit": "bam", "rank": "6", "colors": ["g"], "points": 1},
	{"cardId": "bam7", "suit": "bam", "rank": "7", "colors": ["g"], "points": 1},
	{"cardId": "bam8", "suit": "bam", "rank": "8", "colors": ["g"], "points": 1},
	{"cardId": "bam9", "suit": "bam", "rank": "9", "colors": ["g"], "points": 1},
]

const CRACKS := [
	{"cardId": "crack1", "suit": "crack", "rank": "1", "colors": ["r"], "points": 1},
	{"cardId": "crack2", "suit": "crack", "rank": "2", "colors": ["r"], "points": 1},
	{"cardId": "crack3", "suit": "crack", "rank": "3", "colors": ["r"], "points": 1},
	{"cardId": "crack4", "suit": "crack", "rank": "4", "colors": ["r"], "points": 1},
	{"cardId": "crack5", "suit": "crack", "rank": "5", "colors": ["r"], "points": 1},
	{"cardId": "crack6", "suit": "crack", "rank": "6", "colors": ["r"], "points": 1},
	{"cardId": "crack7", "suit": "crack", "rank": "7", "colors": ["r"], "points": 1},
	{"cardId": "crack8", "suit": "crack", "rank": "8", "colors": ["r"], "points": 1},
	{"cardId": "crack9", "suit": "crack", "rank": "9", "colors": ["r"], "points": 1},
]

const DOTS := [
	{"cardId": "dot1", "suit": "dot", "rank": "1", "colors": ["b"], "points": 1},
	{"cardId": "dot2", "suit": "dot", "rank": "2", "colors": ["b"], "points": 1},
	{"cardId": "dot3", "suit": "dot", "rank": "3", "colors": ["b"], "points": 1},
	{"cardId": "dot4", "suit": "dot", "rank": "4", "colors": ["b"], "points": 1},
	{"cardId": "dot5", "suit": "dot", "rank": "5", "colors": ["b"], "points": 1},
	{"cardId": "dot6", "suit": "dot", "rank": "6", "colors": ["b"], "points": 1},
	{"cardId": "dot7", "suit": "dot", "rank": "7", "colors": ["b"], "points": 1},
	{"cardId": "dot8", "suit": "dot", "rank": "8", "colors": ["b"], "points": 1},
	{"cardId": "dot9", "suit": "dot", "rank": "9", "colors": ["b"], "points": 1},
]

const WINDS := [
	{"cardId": "windn", "suit": "wind", "rank": "n", "colors": ["k"], "points": 3},
	{"cardId": "windw", "suit": "wind", "rank": "w", "colors": ["k"], "points": 3},
	{"cardId": "winds", "suit": "wind", "rank": "s", "colors": ["k"], "points": 3},
	{"cardId": "winde", "suit": "wind", "rank": "e", "colors": ["k"], "points": 3},
]

const DRAGONS := [
	{"cardId": "dragonr", "suit": "dragon", "rank": "r", "colors": ["r"], "points": 2},
	{"cardId": "dragong", "suit": "dragon", "rank": "g", "colors": ["g"], "points": 2},
	{"cardId": "dragonb", "suit": "dragon", "rank": "b", "colors": ["b"], "points": 2},
	{"cardId": "dragonk", "suit": "dragon", "rank": "k", "colors": ["k"], "points": 2},
]

const RABBITS := [
	{"cardId": "rabbitr", "suit": "rabbit", "rank": "r", "colors": ["r"], "points": 2},
	{"cardId": "rabbitg", "suit": "rabbit", "rank": "g", "colors": ["g"], "points": 2},
	{"cardId": "rabbitb", "suit": "rabbit", "rank": "b", "colors": ["b"], "points": 2},
]

const FROGS := [
	{"cardId": "frogr", "suit": "frog", "rank": "r", "colors": ["r"], "points": 2},
	{"cardId": "frogb", "suit": "frog", "rank": "b", "colors": ["b"], "points": 2},
	{"cardId": "frogg", "suit": "frog", "rank": "g", "colors": ["g"], "points": 2},
]

const LOTUSES := [
	{"cardId": "lotusr", "suit": "lotus", "rank": "r", "colors": ["r"], "points": 2},
	{"cardId": "lotusb", "suit": "lotus", "rank": "b", "colors": ["b"], "points": 2},
	{"cardId": "lotusg", "suit": "lotus", "rank": "g", "colors": ["g"], "points": 2},
]

const SHADOWS := [
	{"cardId": "shadowr", "suit": "shadow", "rank": "r", "colors": ["r", "k"], "points": 10},
	{"cardId": "shadowb", "suit": "shadow", "rank": "b", "colors": ["b", "k"], "points": 10},
	{"cardId": "shadowg", "suit": "shadow", "rank": "g", "colors": ["g", "k"], "points": 10},
]

const SPARROWS := [
	{"cardId": "sparrowr", "suit": "sparrow", "rank": "r", "colors": ["r"], "points": 2},
	{"cardId": "sparrowb", "suit": "sparrow", "rank": "b", "colors": ["b"], "points": 2},
	{"cardId": "sparrowg", "suit": "sparrow", "rank": "g", "colors": ["g"], "points": 2},
]

const PHOENIXES := [
	{"cardId": "phoenix", "suit": "phoenix", "rank": "", "colors": ["k"], "points": 2},
]

const TAIJITU := [
	{"cardId": "taijitur", "suit": "taijitu", "rank": "r", "colors": ["r"], "points": 8},
	{"cardId": "taijitug", "suit": "taijitu", "rank": "g", "colors": ["g"], "points": 8},
	{"cardId": "taijitub", "suit": "taijitu", "rank": "b", "colors": ["b"], "points": 8},
]

const MUTATIONS := [
	{"cardId": "mutation1", "suit": "mutation", "rank": "", "colors": ["r", "g"], "points": 4},
	{"cardId": "mutation2", "suit": "mutation", "rank": "", "colors": ["b", "r"], "points": 4},
	{"cardId": "mutation3", "suit": "mutation", "rank": "", "colors": ["g", "b"], "points": 4},
]

const FLOWERS := [
	{"cardId": "flower1", "suit": "flower", "rank": "", "colors": ["r", "g", "b"], "points": 4},
	{"cardId": "flower2", "suit": "flower", "rank": "", "colors": ["r", "g", "b"], "points": 4},
	{"cardId": "flower3", "suit": "flower", "rank": "", "colors": ["r", "g", "b"], "points": 4},
]

const ELEMENTS := [
	{"cardId": "elementr", "suit": "element", "rank": "r", "colors": ["r"], "points": 5},
	{"cardId": "elementg", "suit": "element", "rank": "g", "colors": ["g"], "points": 5},
	{"cardId": "elementb", "suit": "element", "rank": "b", "colors": ["b"], "points": 5},
	{"cardId": "elementk", "suit": "element", "rank": "k", "colors": ["k"], "points": 5},
]

const GEMS := [
	{"cardId": "gemr", "suit": "gem", "rank": "r", "colors": ["r"], "points": 6},
	{"cardId": "gemg", "suit": "gem", "rank": "g", "colors": ["g"], "points": 6},
	{"cardId": "gemb", "suit": "gem", "rank": "b", "colors": ["b"], "points": 6},
	{"cardId": "gemk", "suit": "gem", "rank": "k", "colors": ["k"], "points": 6},
]

const JOKERS := [
	{"cardId": "joker", "suit": "joker", "rank": "", "colors": ["g", "r", "b", "k"], "points": 8},
]

static var _cards_by_id: Dictionary = {}


static func get_all_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	# 统一卡池入口：返回所有可用牌定义。
	cards.append_array(BAMS)
	cards.append_array(CRACKS)
	cards.append_array(DOTS)
	cards.append_array(WINDS)
	cards.append_array(DRAGONS)
	cards.append_array(FLOWERS)
	cards.append_array(JOKERS)
	cards.append_array(FROGS)
	cards.append_array(LOTUSES)
	cards.append_array(SPARROWS)
	cards.append_array(RABBITS)
	cards.append_array(PHOENIXES)
	cards.append_array(ELEMENTS)
	cards.append_array(MUTATIONS)
	cards.append_array(TAIJITU)
	cards.append_array(GEMS)
	cards.append_array(SHADOWS)
	return cards


static func get_card_by_id(card_id: String) -> Dictionary:
	# 惰性构建索引，避免场景加载时做无谓初始化。
	if _cards_by_id.is_empty():
		_build_card_index()
	return _cards_by_id.get(card_id, {})


static func is_valid_material(material: String) -> bool:
	return MATERIALS.has(material)


static func _build_card_index() -> void:
	# 通过 cardId 做 O(1) 查询，供运行时频繁读取。
	for card in get_all_cards():
		_cards_by_id[card["cardId"]] = card
