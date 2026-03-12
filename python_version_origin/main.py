"""
Whatajong - 麻将消除 Roguelite
Python + Pygame 版本

主游戏文件
"""

import pygame
import sys
import random
import time
from typing import Optional

from game import (
    Tile, TileDb, Game, DeckTile,
    get_card, get_initial_pairs, cards_match,
    is_free, get_free_tiles, get_available_pairs,
    game_over_condition, delete_tiles,
    get_points, get_coins, get_taijitu_multiplier,
    get_material, ALL_CARDS, BAMS, CRACKS, DOTS,
    WINDS, DRAGONS,
    Material, is_rabbit,
)
from maps import (
    RESPONSIVE_MAP, get_map, setup_tile_positions,
    get_tile_screen_position, get_sort_key,
    map_get_width, map_get_height, map_get_levels,
)


# ==================== 常量定义 ====================

SCREEN_WIDTH = 1200
SCREEN_HEIGHT = 800
FPS = 60

# 颜色定义
COLORS = {
    "background": (30, 40, 50),
    "background_gradient": (20, 25, 35),
    "tile_base": (245, 240, 230),
    "tile_shadow": (160, 155, 145),
    "tile_highlight": (255, 245, 200),
    "tile_selected": (255, 200, 80),
    "tile_blocked": (140, 140, 150),
    "text_dark": (25, 25, 35),
    "text_light": (240, 240, 250),
    "text_disabled": (100, 100, 110),
    "ui_bg": (45, 55, 75),
    "ui_border": (90, 100, 130),
    "red": (220, 50, 50),
    "green": (50, 170, 70),
    "blue": (50, 110, 210),
    "black": (35, 35, 45),
    "gold": (255, 200, 0),
    "white": (255, 255, 255),
}

# 牌尺寸
TILE_WIDTH = 54
TILE_HEIGHT = 72
TILE_DEPTH = 4

# 牌面颜色映射
SUIT_COLORS = {
    "bam": COLORS["green"],
    "crack": COLORS["red"],
    "dot": COLORS["blue"],
    "wind": COLORS["black"],
    "dragon": COLORS["red"],
    "flower": COLORS["gold"],
    "phoenix": COLORS["gold"],
}


# ==================== 游戏类 ====================

class WhatajongGame:
    """主游戏类"""
    
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("Whatajong - Python 版 | 空格提示 R 重开 ESC 退出")
        
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        self.clock = pygame.time.Clock()
        
        # 初始化字体
        self._init_fonts()
        
        # 游戏状态
        self.tile_db = TileDb()
        self.game = Game()
        self.deck: list[DeckTile] = []
        
        # 交互状态
        self.selected_tile: Optional[Tile] = None
        self.hover_tile: Optional[Tile] = None
        
        # 动画
        self.animations: dict[str, dict] = {}
        self.particle_effects: list[dict] = []
        
        # 计算偏移
        map_w = map_get_width()
        total_width = map_w * TILE_WIDTH * 0.65
        self.offset_x = int((SCREEN_WIDTH - total_width) // 2)
        self.offset_y = 120
        
        # 初始化游戏
        self.new_game()
        
        # 背景表面（预渲染）
        self._bg_surface = self._create_background()
    
    def _init_fonts(self):
        """初始化字体"""
        # 尝试多种中文字体
        chinese_fonts = [
            "C:/Windows/Fonts/msyh.ttc",      # 微软雅黑
            "C:/Windows/Fonts/simsun.ttc",    # 宋体
            "C:/Windows/Fonts/simhei.ttf",    # 黑体
            "C:/Windows/Fonts/simkai.ttf",    # 楷体
            "C:/Windows/Fonts/malgun.ttf",    # Malgun Gothic (韩文但支持中文)
            "C:/Windows/Fonts/yugothic.ttf",  # Yu Gothic (日文但支持中文)
        ]
        
        font_loaded = False
        for font_path in chinese_fonts:
            try:
                self.font_large = pygame.font.Font(font_path, 42)
                self.font_medium = pygame.font.Font(font_path, 26)
                self.font_small = pygame.font.Font(font_path, 18)
                self.font_tiny = pygame.font.Font(font_path, 14)
                font_loaded = True
                print(f"字体加载成功：{font_path}")
                break
            except Exception as e:
                continue
        
        if not font_loaded:
            # 使用默认字体
            print("使用中文字体失败，使用默认字体")
            self.font_large = pygame.font.Font(None, 42)
            self.font_medium = pygame.font.Font(None, 26)
            self.font_small = pygame.font.Font(None, 18)
            self.font_tiny = pygame.font.Font(None, 14)
    
    def _create_background(self) -> pygame.Surface:
        """创建背景渐变"""
        surface = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT))
        
        # 垂直渐变
        for y in range(SCREEN_HEIGHT):
            ratio = y / SCREEN_HEIGHT
            r = int(COLORS["background_gradient"][0] * (1 - ratio) + COLORS["background"][0] * ratio)
            g = int(COLORS["background_gradient"][1] * (1 - ratio) + COLORS["background"][1] * ratio)
            b = int(COLORS["background_gradient"][2] * (1 - ratio) + COLORS["background"][2] * ratio)
            pygame.draw.line(surface, (r, g, b), (0, y), (SCREEN_WIDTH, y))
        
        return surface
    
    def new_game(self, seed: Optional[str] = None):
        """开始新游戏"""
        if seed is None:
            seed = str(random.randint(100000, 999999))
        
        print(f"新游戏开始，种子：{seed}")
        
        # 创建牌组
        self.deck = self._create_deck()
        
        # 设置牌位置
        positions = setup_tile_positions(self.deck, seed)
        
        # 初始化数据库
        tiles = {}
        for tile_id, tile_data in positions.items():
            tile = Tile(
                id=tile_data["id"],
                card_id=tile_data["card_id"],
                x=tile_data["x"],
                y=tile_data["y"],
                z=tile_data["z"],
                material=tile_data["material"],
            )
            tiles[tile_id] = tile
        
        self.tile_db.update(tiles)
        
        # 重置游戏状态
        self.game = Game()
        self.selected_tile = None
        self.animations.clear()
        self.particle_effects.clear()
    
    def _create_deck(self) -> list[DeckTile]:
        """创建牌组"""
        deck = []
        tile_id = 0
        
        # 添加初始牌对（每种牌 2 张）
        pairs = get_initial_pairs()
        for card1, card2 in pairs:
            for card in [card1, card2]:
                deck.append(DeckTile(
                    id=f"tile_{tile_id}",
                    card_id=card.id,
                    material="bone"
                ))
                tile_id += 1
        
        # 添加额外牌
        extra_cards = [
            *DOTS[:3],
            *WINDS[:2],
            *DRAGONS[:2],
        ]
        
        for card in extra_cards:
            deck.append(DeckTile(
                id=f"tile_{tile_id}",
                card_id=card.id,
                material="bone"
            ))
            tile_id += 1
        
        print(f"创建牌组：{len(deck)} 张牌")
        return deck
    
    def handle_events(self):
        """处理事件"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            
            if event.type == pygame.MOUSEMOTION:
                self._handle_mouse_motion(event.pos)
            
            if event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # 左键
                    self._handle_click(event.pos)
            
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    return False
                if event.key == pygame.K_r:
                    self.new_game()
                if event.key == pygame.K_SPACE:
                    self._show_hint()
        
        return True
    
    def _handle_mouse_motion(self, pos: tuple[int, int]):
        """处理鼠标移动"""
        self.hover_tile = self._get_tile_at_position(pos)
    
    def _handle_click(self, pos: tuple[int, int]):
        """处理鼠标点击"""
        if self.game.pause and self.game.end_condition:
            return
        
        tile = self._get_tile_at_position(pos)
        
        if tile and not tile.deleted and is_free(self.tile_db, tile, self.game):
            self._select_tile(tile)
    
    def _get_tile_at_position(self, screen_pos: tuple[int, int]) -> Optional[Tile]:
        """根据屏幕位置获取牌"""
        mouse_x, mouse_y = screen_pos
        
        # 从后往前检查（先检查上层）
        tiles = sorted(
            [t for t in self.tile_db.all() if not t.deleted],
            key=get_sort_key,
            reverse=True
        )
        
        for tile in tiles:
            screen_x, screen_y = get_tile_screen_position(
                tile.x, tile.y, tile.z,
                TILE_WIDTH, TILE_HEIGHT,
                self.offset_x, self.offset_y
            )
            
            # 检查是否在牌范围内
            if (screen_x <= mouse_x <= screen_x + TILE_WIDTH and
                screen_y <= mouse_y <= screen_y + TILE_HEIGHT):
                return tile
        
        return None
    
    def _select_tile(self, tile: Tile):
        """选择牌"""
        if self.selected_tile is None:
            # 选择第一张牌
            self.selected_tile = tile
            tile.selected = True
        elif self.selected_tile.id == tile.id:
            # 取消选择
            self.selected_tile.selected = False
            self.selected_tile = None
        else:
            # 尝试匹配
            first_tile = self.selected_tile
            
            if cards_match(first_tile.card_id, tile.card_id):
                # 匹配成功
                self._match_tiles(first_tile, tile)
            else:
                # 匹配失败，切换选择
                first_tile.selected = False
                self.selected_tile = tile
                tile.selected = True
    
    def _match_tiles(self, tile1: Tile, tile2: Tile):
        """匹配两张牌"""
        # 取消选择
        tile1.selected = False
        tile2.selected = False
        self.selected_tile = None
        
        # 计算分数
        multiplier = get_taijitu_multiplier((tile1, tile2))
        
        points1 = get_points(self.game, tile1, self.tile_db) * multiplier
        points2 = get_points(self.game, tile2, self.tile_db) * multiplier
        
        coins1 = get_coins(tile1, self.game, self.tile_db)
        coins2 = get_coins(tile2, self.game, self.tile_db)
        
        # 更新游戏状态
        self.game.points += points1 + points2
        self.game.coins += coins1 + coins2
        
        # 创建消除动画
        self._create_delete_effect(tile1)
        self._create_delete_effect(tile2)
        
        # 标记为已删除
        tile1.deleted = True
        tile2.deleted = True
        
        # 检查游戏结束
        end_condition = game_over_condition(self.tile_db, self.game)
        if end_condition:
            self.game.pause = True
            self.game.end_condition = end_condition
    
    def _create_delete_effect(self, tile: Tile):
        """创建消除粒子效果"""
        screen_x, screen_y = get_tile_screen_position(
            tile.x, tile.y, tile.z,
            TILE_WIDTH, TILE_HEIGHT,
            self.offset_x, self.offset_y
        )
        
        # 创建粒子
        for _ in range(15):
            self.particle_effects.append({
                "x": screen_x + TILE_WIDTH // 2,
                "y": screen_y + TILE_HEIGHT // 2,
                "vx": random.uniform(-5, 5),
                "vy": random.uniform(-5, 5),
                "life": 30,
                "color": random.choice([COLORS["gold"], COLORS["white"], COLORS["tile_base"]]),
                "size": random.randint(3, 8),
            })
        
        self.animations[tile.id] = {"type": "delete", "timer": 20}
    
    def _show_hint(self):
        """显示提示"""
        pairs = get_available_pairs(self.tile_db, self.game)
        if pairs:
            tile1, tile2 = pairs[0]
            self.animations[f"hint_{tile1.id}"] = {"type": "hint", "timer": 90}
            self.animations[f"hint_{tile2.id}"] = {"type": "hint", "timer": 90}
    
    def update(self):
        """更新游戏状态"""
        # 更新游戏时间
        self.game.time = pygame.time.get_ticks() / 1000.0
        
        # 更新动画
        for anim_id, anim in list(self.animations.items()):
            anim["timer"] -= 1
            if anim["timer"] <= 0:
                del self.animations[anim_id]
        
        # 更新粒子
        for particle in self.particle_effects[:]:
            particle["x"] += particle["vx"]
            particle["y"] += particle["vy"]
            particle["vy"] += 0.2  # 重力
            particle["life"] -= 1
            if particle["life"] <= 0:
                self.particle_effects.remove(particle)
    
    def draw(self):
        """绘制游戏画面"""
        # 绘制背景
        self.screen.blit(self._bg_surface, (0, 0))
        
        # 绘制牌（按正确顺序）
        tiles = sorted(
            [t for t in self.tile_db.all() if not t.deleted],
            key=get_sort_key
        )
        
        for tile in tiles:
            self._draw_tile(tile)
        
        # 绘制粒子效果
        self._draw_particles()
        
        # 绘制 UI
        self._draw_ui()
        
        # 绘制游戏结束画面
        if self.game.pause and self.game.end_condition:
            self._draw_game_over()
        
        pygame.display.flip()
    
    def _draw_tile(self, tile: Tile):
        """绘制单张牌"""
        screen_x, screen_y = get_tile_screen_position(
            tile.x, tile.y, tile.z,
            TILE_WIDTH, TILE_HEIGHT,
            self.offset_x, self.offset_y
        )
        
        # 检查是否为自由牌
        is_free_tile = is_free(self.tile_db, tile, self.game)
        card = get_card(tile.card_id)
        
        # 绘制牌阴影（3D 效果）
        for i in range(3, 0, -1):
            shadow_rect = pygame.Rect(
                screen_x + i, screen_y + i,
                TILE_WIDTH, TILE_HEIGHT
            )
            pygame.draw.rect(self.screen, COLORS["tile_shadow"], shadow_rect, border_radius=4)
        
        # 绘制牌主体
        tile_rect = pygame.Rect(
            screen_x, screen_y,
            TILE_WIDTH, TILE_HEIGHT
        )
        
        # 根据状态选择颜色
        if tile.selected:
            base_color = COLORS["tile_selected"]
            border_color = COLORS["gold"]
            border_width = 3
        elif not is_free_tile:
            base_color = COLORS["tile_blocked"]
            border_color = COLORS["text_disabled"]
            border_width = 1
        else:
            base_color = COLORS["tile_base"]
            border_color = COLORS["text_dark"]
            border_width = 2
        
        pygame.draw.rect(self.screen, base_color, tile_rect, border_radius=4)
        pygame.draw.rect(self.screen, border_color, tile_rect, border_width, border_radius=4)
        
        # 绘制牌面图案
        self._draw_tile_face(tile, screen_x, screen_y, card)
        
        # 绘制材质指示
        material = get_material(tile, self.tile_db, self.game)
        if material != "bone":
            self._draw_material_indicator(screen_x, screen_y, material)
        
        # 绘制提示动画
        hint_key = f"hint_{tile.id}"
        if hint_key in self.animations:
            self._draw_hint_effect(screen_x, screen_y)
    
    def _draw_tile_face(self, tile: Tile, screen_x: int, screen_y: int, card):
        """绘制牌面图案"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        # 获取牌的颜色
        suit_color = SUIT_COLORS.get(card.suit, COLORS["text_dark"])
        
        # 根据牌类型绘制不同图案
        if card.suit in ["bam", "crack", "dot"]:
            # 数字牌：绘制数字和背景
            self._draw_number_tile(screen_x, screen_y, card, suit_color)
        elif card.suit == "wind":
            # 风牌
            self._draw_wind_tile(screen_x, screen_y, card, suit_color)
        elif card.suit == "dragon":
            # 龙牌
            self._draw_dragon_tile(screen_x, screen_y, card, suit_color)
        elif card.suit == "flower":
            # 花牌
            self._draw_flower_tile(screen_x, screen_y, card)
        elif card.suit == "phoenix":
            # 凤凰牌
            self._draw_phoenix_tile(screen_x, screen_y, card)
        else:
            # 其他牌：简单绘制
            self._draw_simple_tile(screen_x, screen_y, card, suit_color)
    
    def _draw_number_tile(self, screen_x: int, screen_y: int, card, color):
        """绘制数字牌"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        # 绘制数字
        try:
            # 将数字转换为中文
            num_map = {"1": "一", "2": "二", "3": "三", "4": "四", "5": "五",
                      "6": "六", "7": "七", "8": "八", "9": "九"}
            chinese_num = num_map.get(card.rank, card.rank)
            
            text_surface = self.font_medium.render(chinese_num, True, color)
            text_rect = text_surface.get_rect(center=(center_x, center_y - 5))
            self.screen.blit(text_surface, text_rect)
            
            # 绘制花色符号
            suit_symbol = self._get_suit_symbol(card.suit)
            symbol_surface = self.font_small.render(suit_symbol, True, color)
            symbol_rect = symbol_surface.get_rect(center=(center_x, center_y + 20))
            self.screen.blit(symbol_surface, symbol_rect)
        except:
            # 字体不支持时绘制简单图案
            pygame.draw.circle(self.screen, color, (center_x, center_y), 15)
    
    def _draw_wind_tile(self, screen_x: int, screen_y: int, card, color):
        """绘制风牌"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        wind_map = {"n": "北", "w": "西", "s": "南", "e": "东"}
        wind_char = wind_map.get(card.rank, "?")
        
        try:
            text_surface = self.font_medium.render(wind_char, True, color)
            text_rect = text_surface.get_rect(center=(center_x, center_y))
            self.screen.blit(text_surface, text_rect)
        except:
            pygame.draw.circle(self.screen, color, (center_x, center_y), 15)
    
    def _draw_dragon_tile(self, screen_x: int, screen_y: int, card, color):
        """绘制龙牌"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        dragon_map = {"r": "中", "g": "发", "b": "白", "k": "黑"}
        dragon_char = dragon_map.get(card.rank, "?")
        
        try:
            text_surface = self.font_medium.render(dragon_char, True, color)
            text_rect = text_surface.get_rect(center=(center_x, center_y))
            self.screen.blit(text_surface, text_rect)
        except:
            # 绘制龙形图案
            pygame.draw.polygon(self.screen, color, [
                (center_x, center_y - 15),
                (center_x - 12, center_y + 10),
                (center_x + 12, center_y + 10),
            ])
    
    def _draw_flower_tile(self, screen_x: int, screen_y: int, card):
        """绘制花牌"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        # 绘制花朵图案
        for i in range(5):
            angle = i * 72
            rad = pygame.math.Vector2(1, 0).rotate(angle)
            petal_x = center_x + int(rad.x * 10)
            petal_y = center_y + int(rad.y * 10)
            pygame.draw.circle(self.screen, COLORS["red"], (petal_x, petal_y), 5)
        
        pygame.draw.circle(self.screen, COLORS["gold"], (center_x, center_y), 6)
    
    def _draw_phoenix_tile(self, screen_x: int, screen_y: int, card):
        """绘制凤凰牌"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        # 绘制凤凰图案（简化为鸟形）
        pygame.draw.ellipse(self.screen, COLORS["gold"], 
                          (center_x - 15, center_y - 10, 30, 20))
        pygame.draw.circle(self.screen, COLORS["red"], (center_x + 10, center_y - 5), 5)
    
    def _draw_simple_tile(self, screen_x: int, screen_y: int, card, color):
        """绘制简单牌"""
        center_x = screen_x + TILE_WIDTH // 2
        center_y = screen_y + TILE_HEIGHT // 2
        
        try:
            text_surface = self.font_small.render(card.id[:6], True, color)
            text_rect = text_surface.get_rect(center=(center_x, center_y))
            self.screen.blit(text_surface, text_rect)
        except:
            pygame.draw.rect(self.screen, color, 
                           (center_x - 10, center_y - 10, 20, 20), 2)
    
    def _get_suit_symbol(self, suit: str) -> str:
        """获取花色符号"""
        symbols = {"bam": "🀐", "crack": "🀙", "dot": "🀀"}
        return symbols.get(suit, "")
    
    def _draw_material_indicator(self, screen_x: int, screen_y: int, material: Material):
        """绘制材质指示器"""
        material_colors = {
            "topaz": (255, 200, 0),
            "sapphire": (50, 100, 255),
            "garnet": (180, 0, 0),
            "ruby": (220, 0, 50),
            "jade": (0, 180, 0),
            "emerald": (0, 220, 100),
            "quartz": (200, 200, 200),
            "obsidian": (50, 50, 80),
        }
        
        color = material_colors.get(material, COLORS["gold"])
        pygame.draw.circle(self.screen, color, 
                         (screen_x + TILE_WIDTH - 12, screen_y + 12), 6)
        pygame.draw.circle(self.screen, COLORS["white"], 
                         (screen_x + TILE_WIDTH - 12, screen_y + 12), 6, 2)
    
    def _draw_hint_effect(self, screen_x: int, screen_y: int):
        """绘制提示效果"""
        # 脉冲边框
        alpha = (pygame.time.get_ticks() // 100) % 255
        hint_rect = pygame.Rect(
            screen_x - 3, screen_y - 3,
            TILE_WIDTH + 6, TILE_HEIGHT + 6
        )
        pygame.draw.rect(self.screen, COLORS["gold"], hint_rect, 3, border_radius=5)
    
    def _draw_particles(self):
        """绘制粒子效果"""
        for particle in self.particle_effects:
            alpha = min(255, particle["life"] * 8)
            color = (*particle["color"], alpha)
            
            # 创建带透明度的表面
            particle_surface = pygame.Surface((particle["size"] * 2, particle["size"] * 2), pygame.SRCALPHA)
            pygame.draw.circle(particle_surface, (*particle["color"], alpha), 
                             (particle["size"], particle["size"]), particle["size"])
            self.screen.blit(particle_surface, 
                           (int(particle["x"]) - particle["size"], 
                            int(particle["y"]) - particle["size"]))
    
    def _draw_ui(self):
        """绘制 UI 界面"""
        # UI 背景面板
        ui_rect = pygame.Rect(10, 10, 200, 140)
        pygame.draw.rect(self.screen, COLORS["ui_bg"], ui_rect, border_radius=10)
        pygame.draw.rect(self.screen, COLORS["ui_border"], ui_rect, 3, border_radius=10)
        
        # 分数
        score_text = f"分数：{self.game.points}"
        score_surface = self.font_medium.render(score_text, True, COLORS["text_light"])
        self.screen.blit(score_surface, (25, 25))
        
        # 金币
        coins_text = f"金币：{self.game.coins}"
        coins_surface = self.font_medium.render(coins_text, True, COLORS["gold"])
        self.screen.blit(coins_surface, (25, 58))
        
        # 时间
        time_text = f"时间：{self.game.time:.1f}s"
        time_surface = self.font_small.render(time_text, True, COLORS["text_light"])
        self.screen.blit(time_surface, (25, 92))
        
        # 剩余牌数
        remaining = len([t for t in self.tile_db.all() if not t.deleted])
        remaining_text = f"剩余：{remaining} 张"
        remaining_surface = self.font_small.render(remaining_text, True, COLORS["text_light"])
        self.screen.blit(remaining_surface, (25, 118))
        
        # 右侧操作提示面板
        hint_rect = pygame.Rect(SCREEN_WIDTH - 280, 10, 270, 80)
        pygame.draw.rect(self.screen, COLORS["ui_bg"], hint_rect, border_radius=10)
        pygame.draw.rect(self.screen, COLORS["ui_border"], hint_rect, 2, border_radius=10)
        
        hints = [
            "空格 = 提示",
            "R = 重新开始",
            "ESC = 退出游戏",
        ]
        
        for i, hint in enumerate(hints):
            hint_surface = self.font_small.render(hint, True, COLORS["text_light"])
            self.screen.blit(hint_surface, (SCREEN_WIDTH - 265, 20 + i * 25))
    
    def _draw_game_over(self):
        """绘制游戏结束画面"""
        # 半透明遮罩
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 180))
        self.screen.blit(overlay, (0, 0))
        
        # 中心面板
        panel_width = 400
        panel_height = 250
        panel_rect = pygame.Rect(
            (SCREEN_WIDTH - panel_width) // 2,
            (SCREEN_HEIGHT - panel_height) // 2,
            panel_width, panel_height
        )
        
        pygame.draw.rect(self.screen, COLORS["ui_bg"], panel_rect, border_radius=15)
        pygame.draw.rect(self.screen, COLORS["gold"], panel_rect, 4, border_radius=15)
        
        # 游戏结束文字
        if self.game.end_condition == "empty-board":
            text = "🎉 恭喜通关！"
            color = COLORS["gold"]
        else:
            text = "游戏结束"
            color = COLORS["red"]
        
        text_surface = self.font_large.render(text, True, color)
        text_rect = text_surface.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 - 60))
        self.screen.blit(text_surface, text_rect)
        
        # 最终分数
        score_text = f"最终分数：{self.game.points}"
        score_surface = self.font_medium.render(score_text, True, COLORS["text_light"])
        score_rect = score_surface.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2))
        self.screen.blit(score_surface, score_rect)
        
        # 金币
        coins_text = f"金币：{self.game.coins}"
        coins_surface = self.font_medium.render(coins_text, True, COLORS["gold"])
        coins_rect = coins_surface.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 35))
        self.screen.blit(coins_surface, coins_rect)
        
        # 重新开始提示
        restart_text = "按 R 重新开始"
        restart_surface = self.font_small.render(restart_text, True, COLORS["text_light"])
        restart_rect = restart_surface.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 90))
        self.screen.blit(restart_surface, restart_rect)


# ==================== 主函数 ====================

def main():
    """主函数"""
    game = WhatajongGame()
    running = True
    
    print("游戏已启动！")
    print("操作：鼠标点击选牌，空格提示，R 重开，ESC 退出")
    
    while running:
        running = game.handle_events()
        game.update()
        game.draw()
        game.clock.tick(FPS)
    
    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    main()
