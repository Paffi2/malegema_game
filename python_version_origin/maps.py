"""
地图和布局系统
定义麻将牌的摆放布局
"""

from typing import Optional
import json

# 响应式地图数据（简化版）
# 每个数字代表一种牌型索引，null 代表空位
RESPONSIVE_MAP = [
    # Level 0 (底层)
    [
        [None, None, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, None, None],
        [None, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, None],
        [1, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35],
        [2, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48],
        [3, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61],
        [4, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74],
        [5, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87],
        [6, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100],
        [7, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113],
        [8, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126],
        [9, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139],
        [10, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, None],
        [None, 11, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163],
        [None, None, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, None],
    ],
    # Level 1 (中层)
    [
        [None, None, None, None, None, None, None, None, None, None, None, None, None, None],
        [None, None, None, None, 1, 2, 3, 4, 5, 6, None, None, None, None],
        [None, None, None, 1, 2, 3, 4, 5, 6, 7, 8, 9, None, None],
        [None, None, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, None],
        [None, None, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, None],
        [None, None, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, None],
        [None, None, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, None],
        [None, None, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, None],
        [None, None, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, None],
        [None, None, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, None],
        [None, None, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, None],
        [None, None, None, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
        [None, None, None, None, 10, 11, 12, 13, 14, 15, 16, 17, 18, None],
        [None, None, None, None, None, None, None, None, None, None, None, None, None, None],
    ],
    # Level 2 (顶层)
    [
        [None, None, None, None, None, None, None, None, None, None, None, None, None, None],
        [None, None, None, None, None, None, None, None, None, None, None, None, None, None],
        [None, None, None, None, None, 1, 2, 3, None, None, None, None, None, None],
        [None, None, None, None, 1, 2, 3, 4, 5, None, None, None, None, None],
        [None, None, None, 1, 2, 3, 4, 5, 6, 7, None, None, None, None],
        [None, None, None, 2, 3, 4, 5, 6, 7, 8, None, None, None, None],
        [None, None, None, 3, 4, 5, 6, 7, 8, 9, None, None, None, None],
        [None, None, None, 4, 5, 6, 7, 8, 9, 10, None, None, None, None],
        [None, None, None, 5, 6, 7, 8, 9, 10, 11, None, None, None, None],
        [None, None, None, 6, 7, 8, 9, 10, 11, 12, None, None, None, None],
        [None, None, None, None, 7, 8, 9, 10, 11, 12, None, None, None, None],
        [None, None, None, None, None, 8, 9, 10, 11, None, None, None, None, None],
        [None, None, None, None, None, None, None, None, None, None, None, None, None, None],
        [None, None, None, None, None, None, None, None, None, None, None, None, None, None],
    ],
]


def map_get(map_data: list, x: int, y: int, z: int) -> Optional[int]:
    """安全地获取地图数据"""
    if x < 0 or y < 0 or z < 0:
        return None
    try:
        return map_data[z][y][x]
    except (IndexError, TypeError):
        return None


def map_get_width() -> int:
    """获取地图宽度"""
    return len(RESPONSIVE_MAP[0][0])


def map_get_height() -> int:
    """获取地图高度"""
    return len(RESPONSIVE_MAP[0])


def map_get_levels() -> int:
    """获取地图层数"""
    return len(RESPONSIVE_MAP)


def get_map(tile_count: int) -> list:
    """
    根据牌的数量获取限制后的地图
    :param tile_count: 牌的数量
    :return: 限制后的地图
    """
    import copy
    limited_map = copy.deepcopy(RESPONSIVE_MAP)
    
    for z in range(len(limited_map)):
        for y in range(len(limited_map[z])):
            for x in range(len(limited_map[z][y])):
                tile = limited_map[z][y][x]
                if tile is not None and tile > tile_count:
                    limited_map[z][y][x] = None
    
    return limited_map


def get_map_dimensions() -> tuple[int, int, int]:
    """获取地图尺寸"""
    return (map_get_width(), map_get_height(), map_get_levels())


# ==================== 牌位置设置 ====================

def setup_tile_positions(deck: list, seed: str = "default") -> dict:
    """
    设置牌的位置
    :param deck: 牌组列表
    :param seed: 随机种子
    :return: 牌位置字典
    """
    import random
    
    # 使用种子初始化随机数
    rng = random.Random(seed)
    
    # 获取可用位置
    positions = []
    for z in range(map_get_levels()):
        for y in range(map_get_height()):
            for x in range(map_get_width()):
                tile_index = map_get(RESPONSIVE_MAP, x, y, z)
                if tile_index is not None:
                    positions.append((x, y, z))
    
    # 打乱位置
    rng.shuffle(positions)
    
    # 分配位置
    tiles = {}
    for i, deck_tile in enumerate(deck):
        if i < len(positions):
            x, y, z = positions[i]
            tiles[deck_tile.id] = {
                "id": deck_tile.id,
                "card_id": deck_tile.card_id,
                "x": x,
                "y": y,
                "z": z,
                "deleted": False,
                "selected": False,
                "material": deck_tile.material,
                "points": 0,
                "coins": 0,
            }
    
    return tiles


def get_tile_screen_position(x: int, y: int, z: int, 
                             tile_width: int = 60,
                             tile_height: int = 80,
                             offset_x: int = 100,
                             offset_y: int = 50) -> tuple[int, int]:
    """
    将地图坐标转换为屏幕坐标
    :param x: 地图 X 坐标
    :param y: 地图 Y 坐标
    :param z: 地图 Z 坐标（层数）
    :param tile_width: 牌宽度
    :param tile_height: 牌高度
    :param offset_x: X 偏移
    :param offset_y: Y 偏移
    :return: 屏幕坐标 (screen_x, screen_y)
    """
    # 等距投影效果
    screen_x = offset_x + x * (tile_width * 0.6) - y * (tile_width * 0.6)
    screen_y = offset_y + x * (tile_height * 0.3) + y * (tile_height * 0.3) - z * (tile_height * 0.7)
    
    return (int(screen_x), int(screen_y))


def get_sort_key(tile) -> tuple:
    """
    获取牌的排序键（用于正确的渲染顺序）
    :param tile: 牌对象
    :return: 排序键 (z, x+y)
    """
    return (tile.z, tile.x + tile.y)
