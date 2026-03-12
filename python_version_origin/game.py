"""
Whatajong - 麻将消除 Roguelite 游戏核心逻辑
Python 版本
"""

from dataclasses import dataclass, field
from typing import Literal, Optional, TypedDict
from enum import Enum
import random


# ==================== 基础类型定义 ====================

Color = Literal["g", "r", "b", "k"]
Material = Literal[
    "bone", "topaz", "sapphire", "garnet", "ruby",
    "jade", "emerald", "quartz", "obsidian"
]
Suit = Literal["bam", "crack", "dot", "dragon", "wind", 
               "rabbit", "frog", "lotus", "shadow", "sparrow",
               "phoenix", "taijitu", "mutation", "flower", 
               "element", "gem", "joker"]


# ==================== 牌型定义 ====================

@dataclass(frozen=True)
class Card:
    id: str
    suit: Suit
    rank: str
    colors: list[Color]
    points: int = 1


# 万子 (Bamboo)
BAMS = [
    Card("bam1", "bam", "1", ["g"]),
    Card("bam2", "bam", "2", ["g"]),
    Card("bam3", "bam", "3", ["g"]),
    Card("bam4", "bam", "4", ["g"]),
    Card("bam5", "bam", "5", ["g"]),
    Card("bam6", "bam", "6", ["g"]),
    Card("bam7", "bam", "7", ["g"]),
    Card("bam8", "bam", "8", ["g"]),
    Card("bam9", "bam", "9", ["g"]),
]

# 筒子 (Cracks)
CRACKS = [
    Card("crack1", "crack", "1", ["r"]),
    Card("crack2", "crack", "2", ["r"]),
    Card("crack3", "crack", "3", ["r"]),
    Card("crack4", "crack", "4", ["r"]),
    Card("crack5", "crack", "5", ["r"]),
    Card("crack6", "crack", "6", ["r"]),
    Card("crack7", "crack", "7", ["r"]),
    Card("crack8", "crack", "8", ["r"]),
    Card("crack9", "crack", "9", ["r"]),
]

# 索子 (Dots)
DOTS = [
    Card("dot1", "dot", "1", ["b"]),
    Card("dot2", "dot", "2", ["b"]),
    Card("dot3", "dot", "3", ["b"]),
    Card("dot4", "dot", "4", ["b"]),
    Card("dot5", "dot", "5", ["b"]),
    Card("dot6", "dot", "6", ["b"]),
    Card("dot7", "dot", "7", ["b"]),
    Card("dot8", "dot", "8", ["b"]),
    Card("dot9", "dot", "9", ["b"]),
]

# 风牌 (Winds)
WINDS = [
    Card("windn", "wind", "n", ["k"], 3),
    Card("windw", "wind", "w", ["k"], 3),
    Card("winds", "wind", "s", ["k"], 3),
    Card("winde", "wind", "e", ["k"], 3),
]

# 龙牌 (Dragons)
DRAGONS = [
    Card("dragonr", "dragon", "r", ["r"], 2),
    Card("dragong", "dragon", "g", ["g"], 2),
    Card("dragonb", "dragon", "b", ["b"], 2),
    Card("dragonk", "dragon", "k", ["k"], 2),
]

# 兔子 (Rabbits)
RABBITS = [
    Card("rabbitr", "rabbit", "r", ["r"], 2),
    Card("rabbitg", "rabbit", "g", ["g"], 2),
    Card("rabbitb", "rabbit", "b", ["b"], 2),
]

# 青蛙 (Frogs)
FROGS = [
    Card("frogr", "frog", "r", ["r"], 2),
    Card("frogb", "frog", "b", ["b"], 2),
    Card("frogg", "frog", "g", ["g"], 2),
]

# 莲花 (Lotuses)
LOTUSES = [
    Card("lotusr", "lotus", "r", ["r"], 2),
    Card("lotusb", "lotus", "b", ["b"], 2),
    Card("lotusg", "lotus", "g", ["g"], 2),
]

# 影子牌 (Shadows)
SHADOWS = [
    Card("shadowr", "shadow", "r", ["r", "k"], 10),
    Card("shadowb", "shadow", "b", ["b", "k"], 10),
    Card("shadowg", "shadow", "g", ["g", "k"], 10),
]

# 麻雀 (Sparrows)
SPARROWS = [
    Card("sparrowr", "sparrow", "r", ["r"], 2),
    Card("sparrowb", "sparrow", "b", ["b"], 2),
    Card("sparrowg", "sparrow", "g", ["g"], 2),
]

# 凤凰 (Phoenix)
PHOENIXES = [
    Card("phoenix", "phoenix", "", ["k"], 2),
]

# 太极 (Taijitu)
TAIJITU = [
    Card("taijitur", "taijitu", "r", ["r"], 8),
    Card("taijitug", "taijitu", "g", ["g"], 8),
    Card("taijitub", "taijitu", "b", ["b"], 8),
]

# 变异牌 (Mutations)
MUTATIONS = [
    Card("mutation1", "mutation", "", ["r", "g"], 4),
    Card("mutation2", "mutation", "", ["b", "r"], 4),
    Card("mutation3", "mutation", "", ["g", "b"], 4),
]

# 花牌 (Flowers)
FLOWERS = [
    Card("flower1", "flower", "", ["r", "g", "b"], 4),
    Card("flower2", "flower", "", ["r", "g", "b"], 4),
    Card("flower3", "flower", "", ["r", "g", "b"], 4),
]

# 元素牌 (Elements)
ELEMENTS = [
    Card("elementr", "element", "r", ["r"], 5),
    Card("elementg", "element", "g", ["g"], 5),
    Card("elementb", "element", "b", ["b"], 5),
]

# 宝石牌 (Gems)
GEMS = [
    Card("gem1", "gem", "1", ["r", "g", "b"], 6),
    Card("gem2", "gem", "2", ["r", "g", "b"], 6),
    Card("gem3", "gem", "3", ["r", "g", "b"], 6),
]

# 小丑牌 (Jokers)
JOKERS = [
    Card("joker1", "joker", "1", ["k"], 10),
    Card("joker2", "joker", "2", ["k"], 10),
    Card("joker3", "joker", "3", ["k"], 10),
]

# 所有牌
ALL_CARDS: dict[str, Card] = {}
for card_list in [BAMS, CRACKS, DOTS, WINDS, DRAGONS, RABBITS, 
                  FROGS, LOTUSES, SHADOWS, SPARROWS, PHOENIXES,
                  TAIJITU, MUTATIONS, FLOWERS, ELEMENTS, GEMS, JOKERS]:
    for card in card_list:
        ALL_CARDS[card.id] = card


def get_card(card_id: str) -> Card:
    """获取牌的定义"""
    return ALL_CARDS.get(card_id, Card(card_id, "bam", "1", ["g"]))


# ==================== 游戏状态类型 ====================

@dataclass
class Position:
    x: int
    y: int
    z: int


@dataclass
class Tile:
    id: str
    card_id: str
    x: int
    y: int
    z: int
    deleted: bool = False
    selected: bool = False
    material: Material = "bone"
    points: int = 0
    coins: int = 0


@dataclass
class DeckTile:
    id: str
    card_id: str
    material: Material = "bone"


@dataclass
class Game:
    points: int = 0
    coins: int = 0
    time: float = 0.0
    pause: bool = False
    end_condition: Optional[str] = None
    temporary_material: Optional[Material] = None
    dragon_run_combo: int = 0
    dragon_run_color: Optional[Color] = None
    phoenix_run_combo: int = 0
    joker: bool = False


# ==================== 核心游戏逻辑 ====================

def get_material_points(material: Material) -> int:
    """获取材质的基础分数"""
    material_values = {
        "topaz": 1, "quartz": 1, "garnet": 1,
        "jade": 2,
        "sapphire": 24, "obsidian": 24, "ruby": 24,
        "emerald": 48,
        "bone": 0,
    }
    return material_values.get(material, 0)


def is_shiny(material: Material) -> bool:
    """判断材质是否为闪亮材质"""
    return material in ["obsidian", "sapphire", "emerald", "ruby"]


def opacity(material: Material) -> float:
    """获取材质透明度"""
    return 1.0 if material == "bone" else 0.5


def cards_match(card_id1: str, card_id2: str) -> bool:
    """判断两张牌是否匹配"""
    # 花牌互相匹配
    if is_flower(card_id1) and is_flower(card_id2):
        return True
    
    # 青蛙和莲花匹配
    frog_card = is_frog(card_id1)
    lotus_card = is_lotus(card_id2)
    if frog_card and lotus_card and frog_card.rank == lotus_card.rank:
        return True
    
    frog_card = is_frog(card_id2)
    lotus_card = is_lotus(card_id1)
    if frog_card and lotus_card and frog_card.rank == lotus_card.rank:
        return True
    
    # 相同牌匹配
    return card_id1 == card_id2


def is_free(tile_db: "TileDb", tile: Tile, game: Optional[Game] = None) -> bool:
    """判断牌是否可以被点击（自由牌）"""
    if tile.deleted:
        return False
    
    if is_covered(tile_db, tile):
        return False
    
    # 特殊材质总是可用
    material = get_material(tile, tile_db, game)
    if material in ["topaz", "sapphire"]:
        return True
    
    freedoms = get_freedoms(tile_db, tile)
    return freedoms["left"] or freedoms["right"]


def is_covered(tile_db: "TileDb", tile: Tile) -> Optional[Tile]:
    """判断牌是否被覆盖"""
    return overlaps(tile_db, Position(tile.x, tile.y, tile.z + 1))


def overlaps(tile_db: "TileDb", position: Position, z: int = 0) -> Optional[Tile]:
    """判断位置是否有牌重叠"""
    find = get_finder(tile_db, position)
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            tile = find(dx, dy, z)
            if tile:
                return tile
    return None


def get_freedoms(tile_db: "TileDb", tile: Tile) -> dict[str, bool]:
    """获取牌的自由度（左右是否空）"""
    find = get_finder(tile_db, Position(tile.x, tile.y, tile.z))
    
    has_left = find(-2, -1) or find(-2, 0) or find(-2, 1)
    has_right = find(2, -1) or find(2, 0) or find(2, 1)
    has_top = find(-1, -2) or find(0, -2) or find(1, -2)
    has_bottom = find(-1, 2) or find(0, 2) or find(1, 2)
    
    return {
        "left": not has_left,
        "right": not has_right,
        "top": not has_top,
        "bottom": not has_bottom,
    }


def get_finder(tile_db: "TileDb", position: Position):
    """获取查找器函数"""
    def find(dx: int = 0, dy: int = 0, dz: int = 0) -> Optional[Tile]:
        target = tile_db.get_by_coord(
            position.x + dx,
            position.y + dy,
            position.z + dz
        )
        return target if target and not target.deleted else None
    return find


def get_available_pairs(tile_db: "TileDb", game: Optional[Game] = None) -> list[tuple[Tile, Tile]]:
    """获取所有可用的牌对"""
    tiles = get_free_tiles(tile_db, game)
    pairs = []
    
    for i in range(len(tiles)):
        for j in range(i + 1, len(tiles)):
            tile1 = tiles[i]
            tile2 = tiles[j]
            if cards_match(tile1.card_id, tile2.card_id):
                pairs.append((tile1, tile2))
    
    return pairs


def get_free_tiles(tile_db: "TileDb", game: Optional[Game] = None) -> list[Tile]:
    """获取所有可用的牌"""
    return [tile for tile in tile_db.all() 
            if not tile.deleted and is_free(tile_db, tile, game)]


def game_over_condition(tile_db: "TileDb", game: Optional[Game] = None) -> Optional[str]:
    """检查游戏结束条件"""
    tiles_alive = [t for t in tile_db.all() if not t.deleted]
    
    if len(tiles_alive) == 0:
        return "empty-board"
    
    available_pairs = get_available_pairs(tile_db, game)
    if len(available_pairs) == 0:
        return "no-pairs"
    
    return None


# ==================== 牌类型判断函数 ====================

def _check_suit(card_id: str, suit: Suit) -> Optional[Card]:
    card = get_card(card_id)
    return card if card.suit == suit else None


def is_dragon(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "dragon")


def is_mutation(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "mutation")


def is_flower(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "flower")


def is_wind(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "wind")


def is_suit(card_id: str) -> Optional[Card]:
    return is_bam(card_id) or is_crack(card_id) or is_dot(card_id)


def is_bam(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "bam")


def is_crack(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "crack")


def is_dot(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "dot")


def is_rabbit(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "rabbit")


def is_joker(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "joker")


def is_phoenix(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "phoenix")


def is_element(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "element")


def is_frog(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "frog")


def is_gem(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "gem")


def is_sparrow(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "sparrow")


def is_lotus(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "lotus")


def is_taijitu(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "taijitu")


def is_shadow(card_id: str) -> Optional[Card]:
    return _check_suit(card_id, "shadow")


# ==================== 材质和分数计算 ====================

def get_active_shadows(tile_db: "TileDb") -> set[Suit]:
    """获取激活的影子牌"""
    cards = []
    for tile in tile_db.all():
        if not tile.deleted:
            shadow_card = is_shadow(tile.card_id)
            if shadow_card and is_free(tile_db, tile):
                cards.append(shadow_card)
    
    suits = [("bam", "g"), ("crack", "r"), ("dot", "b")]
    result = set()
    
    for suit, color in suits:
        if any(c.rank == color for c in cards):
            result.add(suit)
    
    return result


def get_material(tile: Tile, tile_db: "TileDb", game: Optional[Game] = None) -> Material:
    """获取牌的实际材质"""
    if game and game.temporary_material:
        temporary_material = game.temporary_material
        materials = {
            "topaz": {"color": "b", "evolution": "sapphire"},
            "garnet": {"color": "r", "evolution": "ruby"},
            "jade": {"color": "g", "evolution": "emerald"},
            "quartz": {"color": "k", "evolution": "obsidian"},
        }
        mat_info = materials[temporary_material]
        card = get_card(tile.card_id)
        material = temporary_material if tile.material == "bone" else mat_info["evolution"]
        
        if mat_info["color"] in card.colors:
            return get_shadow_material(tile.card_id, material, tile_db)
    
    return get_shadow_material(tile.card_id, tile.material, tile_db)


def get_shadow_material(card_id: str, material: Material, tile_db: "TileDb") -> Material:
    """获取影子材质"""
    suit_card = is_suit(card_id)
    if not suit_card or material == "bone":
        return material
    
    active_shadows = get_active_shadows(tile_db)
    if active_shadows.has(suit_card.suit):
        return "obsidian" if is_shiny(material) else "quartz"
    
    return material


def get_points(game: Game, tile: Tile, tile_db: "TileDb") -> int:
    """计算牌的分数"""
    material = get_material(tile, tile_db, game)
    raw_points = get_card(tile.card_id).points + get_material_points(material)
    
    dragon_multiplier = game.dragon_run_combo if game.dragon_run_combo else 0
    phoenix_multiplier = game.phoenix_run_combo * 2 if game.phoenix_run_combo else 0
    
    colors = get_card(tile.card_id).colors
    visible_elements = sum(
        1 for color in colors
        for t in tile_db.all()
        if not t.deleted and t.card_id == f"element{color}" and is_free(tile_db, t)
    )
    free_elements = sum(
        1 for color in colors
        for t in tile_db.all()
        if not t.deleted and t.card_id == f"element{color}" and is_free(tile_db, t)
    )
    
    return (raw_points + visible_elements) * max(1, dragon_multiplier + phoenix_multiplier + free_elements)


def get_coins(tile: Tile, game: Game, tile_db: "TileDb") -> int:
    """计算金币"""
    material = get_material(tile, tile_db, game)
    material_coins = {"garnet": 1, "ruby": 3}.get(material, 0)
    rabbit_coins = 1 if is_rabbit(tile.card_id) else 0
    return material_coins + rabbit_coins


def select_tile(tile_db: "TileDb", game: Game, tile_id: str):
    """选择牌"""
    tile = tile_db.get(tile_id)
    if not tile:
        raise ValueError(f"Tile not found: {tile_id}")
    
    first_tile = tile_db.find_by(selected=True)
    
    if not first_tile:
        # 选择第一张牌
        tile.selected = True
        tile_db.set(tile_id, tile)
        return
    
    if first_tile.id == tile_id:
        # 取消选择
        tile.selected = False
        tile_db.set(tile_id, tile)
        return
    
    # 尝试匹配
    first_tile.selected = False
    
    if cards_match(first_tile.card_id, tile.card_id):
        # 匹配成功
        delete_tiles(tile_db, [first_tile, tile])
        
        # 计算分数
        multiplier = get_taijitu_multiplier((first_tile, tile))
        new_points1 = get_points(game, first_tile, tile_db) * multiplier
        new_points2 = get_points(game, tile, tile_db) * multiplier
        new_coins1 = get_coins(first_tile, game, tile_db)
        new_coins2 = get_coins(tile, game, tile_db)
        
        first_tile.points = new_points1
        tile.points = new_points2
        first_tile.coins = new_coins1
        tile.coins = new_coins2
        
        game.points += new_points1 + new_points2
        game.coins += new_coins1 + new_coins2
        
        tile_db.set(first_tile.id, first_tile)
        tile_db.set(tile.id, tile)
    else:
        # 匹配失败，选择新牌
        tile.selected = True
        tile_db.set(tile_id, tile)
    
    # 检查游戏结束
    condition = game_over_condition(tile_db, game)
    if condition:
        game.pause = True
        game.end_condition = condition


def delete_tiles(tile_db: "TileDb", tiles: list[Tile]):
    """删除牌"""
    for tile in tiles:
        tile.deleted = True
        tile.selected = False
        tile_db.set(tile.id, tile)


def get_taijitu_multiplier(tiles: tuple[Tile, Tile]) -> int:
    """获取太极牌倍数"""
    tile1, tile2 = tiles
    if tile1.z != tile2.z:
        return 1
    if not (is_taijitu(tile1.card_id) and is_taijitu(tile2.card_id)):
        return 1
    
    x_dist = abs(tile1.x - tile2.x)
    y_dist = abs(tile1.y - tile2.y)
    is_adjacent = (x_dist == 2 and y_dist < 1) or (x_dist < 1 and y_dist == 2)
    
    return 3 if is_adjacent else 1


# ==================== 初始牌组 ====================

def get_initial_pairs() -> list[tuple[Card, Card]]:
    """获取初始牌对"""
    pairs = []
    regular_tiles = BAMS + CRACKS + DOTS
    
    for tile in regular_tiles:
        pairs.append((tile, tile))
    
    return pairs


# ==================== TileDb 数据库类 ====================

class TileDb:
    """牌数据库"""
    
    def __init__(self):
        self._tiles: dict[str, Tile] = {}
    
    def set(self, tile_id: str, tile: Tile):
        self._tiles[tile_id] = tile
    
    def get(self, tile_id: str) -> Optional[Tile]:
        return self._tiles.get(tile_id)
    
    def get_by_coord(self, x: int, y: int, z: int) -> Optional[Tile]:
        for tile in self._tiles.values():
            if tile.x == x and tile.y == y and tile.z == z and not tile.deleted:
                return tile
        return None
    
    def all(self) -> list[Tile]:
        return list(self._tiles.values())
    
    def filter_by(self, **kwargs) -> list[Tile]:
        result = []
        for tile in self._tiles.values():
            match = True
            for key, value in kwargs.items():
                if not hasattr(tile, key) or getattr(tile, key) != value:
                    match = False
                    break
            if match:
                result.append(tile)
        return result
    
    def find_by(self, **kwargs) -> Optional[Tile]:
        matches = self.filter_by(**kwargs)
        return matches[0] if matches else None
    
    def update(self, tiles: dict[str, Tile]):
        self._tiles = tiles
    
    def clear(self):
        self._tiles.clear()
