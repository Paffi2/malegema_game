
# 0.简单的start_menu

    start_menu.gd

# 1.最小可玩局

    board.gd

1. 搭骨架：先做最小可玩局

- 用你现有 Godot 项目起步：project.godot。
- 先做一个 Board 场景，能显示 tiles，支持点击两张牌。
- 先不做商店、不做奖励、不做特殊牌，只做基础匹配与消除

# 2.复现数据定义

- 把牌定义从 game.ts 迁移成 Godot 数据（建议字典或 Resource）。
- 必须保留 cardId、suit、rank、colors、points。
- 材质系统也要保留：bone/topaz/sapphire/garnet/ruby/jade/emerald/quartz/obsidian。

1. 新增完整卡牌与材质数据脚本[ card_data.gd ](first-demo/scripts/card_data.gd)
3. 在棋盘逻辑中接入卡牌数据读取
   [ board.gd ](first-demo/scripts/board.gd)
4. 每张牌都包含：

- cardId
- suit
- rank
- colors
- points

2. 材质系统完整保留：

- bone
- topaz
- sapphire
- garnet
- ruby
- jade
- emerald
- quartz
- obsidian

与原项目 game.ts 的对应情况

1. 已迁移的牌组：

- bams, cracks, dots
- winds, dragons
- rabbits, frogs, lotuses, sparrows
- phoenixes, taijitu, mutations
- flowers, elements, gems, jokers, shadows

2. 数据访问接口（Godot 可直接调用）：

- get_all_cards()
- get_card_by_id(card_id)
- is_valid_material(material)

当前效果

1. 棋盘依然按最小玩法运行（点击两张匹配消除）。
2. 每个牌按钮会从 card_data 中读取属性，并显示到 tooltip（suit/rank/colors/points），证明数据已经被运行时消费，而不是仅静态存放。

下一步如果继续做第 3 步，我可以直接实现“二维/三维坐标 + 可点击自由牌判定（isFree）”，把玩法从“任意两张可点”升级为更接近 whatajong 的规则。

Made changes.

# 3.复现地图和坐标系统

- 直接迁移 responsive.ts 的三维布局数据。
- 坐标语义保持一致：x/y/z。
- 复现 mapGet、overlaps、fullyOverlaps、isFree 这组判定逻辑（都在 game.ts）。

1. 迁移三维布局数据（直接对应 responsive.ts）[ responsive_map_data.gd ](first-demo/scripts/responsive_map_data.gd)
3. 复现坐标/判定逻辑（对应 game.ts）
   [ tile_rules.gd ](first-demo/scripts/tile_rules.gd)

- map_get
- overlaps
- fully_overlaps
- is_free
- 以及 map_get_width / map_get_height / map_get_levels 等辅助函数

3. 将最小可玩局改为按 x/y/z 坐标摆牌并用 is_free 控制可点击[ board.gd ](first-demo/scripts/board.gd)
4. 场景容器从网格改为绝对定位层，承载坐标摆放
   [ board.tscn ](first-demo/scene/board.tscn)

你现在能直接验证的点

1. 牌位来源于三维地图数据，不再是纯 Grid 随机排布。
2. 每张牌有 x/y/z 坐标（tooltip 可看到）。
3. 点击时会走 is_free 判定：被覆盖或左右受阻的牌不可点。
4. 匹配消除后会刷新整盘可点击状态（overlaps/fully_overlaps/is_free 共同生效）。

校验状态

1. [ responsive_map_data.gd ](first-demo/scripts/responsive_map_data.gd) 无错误
2. [ tile_rules.gd ](first-demo/scripts/tile_rules.gd) 无错误
3. [ board.gd ](first-demo/scripts/board.gd) 无错误
4. [ board.tscn ](first-demo/scene/board.tscn) 无错误

下一步最自然的是第 4 步“可解发牌算法 setupTiles 复现”。如果你确认，我可以继续直接把 setupTiles 的抽对回填算法也迁移到 Godot。

# 4.复现可解发牌算法

（通过**随机移除**再**反向填充**的方式，确保生成的牌局 **总是可解的** 。）

- 完整照搬 setupTiles.ts 的思路：先用 dummy 牌反复“可消对抽取”，确保布局可解，再把真实牌对反向填回。
- 这是 whatajong 手感的关键，不建议自己改算法。

新增可解发牌核心脚本
setup_tiles.gd

补齐地图裁剪逻辑（等价于原版 getMap）
responsive_map_data.gd

补齐可消牌提取辅助（供抽对流程使用）
tile_rules.gd

棋盘切换为使用可解发牌结果
board.gd

已复现的算法流程

用 dummy 牌填入可用坐标位。
反复从当前可点牌中随机抽两张并移除，记录抽取顺序。
如果无法清空剩余牌，整轮重

# 5.复现选牌与结算主循环

- 对照 game.ts 的 selectTile 流程：
  1) 首次点击选中
  2) 二次点击同一张取消
  3) 两张匹配则删除并算分
  4) 两张不匹配尝试跳跃类特殊逻辑
  5) 每次操作后检查 gameOverCondition
- 这里先只做 cardsMatch、deleteTiles、getPoints、gameOverCondition。

本次新增与改动

1. 新增主循环逻辑脚本[ game_loop.gd ](first-demo/scripts/game_loop.gd)
2. 棋盘脚本接入主循环
   [ board.gd ](first-demo/scripts/board.gd)

实现内容对照你的要求

1. 首次点击选中

- 在 `GameLoop.select_tile` 里写入 `selected = true`，返回 `selected-first` 状态。

2. 二次点击同一张取消

- 命中同一 `tile_id` 时取消选中，返回 `unselected`。

3. 两张匹配则删除并算分

- `cards_match` 判断匹配。
- `delete_tiles` 标记删除。
- `get_points` 计算单牌分（牌基础分 + 材质分），匹配后累计到 `game_state.points`。

4. 两张不匹配尝试跳跃类特殊逻辑

- 已加入 `_resolve_jumping_tiles` 调用位。
- 当前按你“先只做基础”要求，函数为占位返回 `false`，不改动牌位。

5. 每次操作后检查 gameOverCondition

- 匹配/不匹配后都会调用 `game_over_condition`。
- 支持 `empty-board` 与 `no-pairs` 两种结束条件。
- board.gd 会根据结束条件更新提示并停止继续操作。

你要求先做的四个函数均已实现

1. `cards_match`
2. `delete_tiles`
3. `get_points`
4. `game_over_condition`

补充说明

1. `cards_match` 已对齐原版基础规则：

- 同 cardId 匹配
- flower 之间互相匹配
- frog 与 lotus 同色匹配（即便你当前牌池里暂未启用，也先对齐逻辑）

2. `get_points` 当前按“基础阶段”实现：

- 牌面 points + material points
- 暂未加入 dragon/phoenix/element/shadow 等乘算链路（符合你这一步范围）

校验结果

1. [ game_loop.gd ](first-demo/scripts/game_loop.gd) 无错误
2. [ board.gd ](first-demo/scripts/board.gd) 无错误

如果你继续下一步，我可以直接把“跳跃类特殊逻辑”从占位实现成真正可用版本（frog/sparrow/lotus 的位移与交换规则）。

# 6.逐个接入特殊牌模块

- 顺序建议：Dragons → Phoenixes → Gems → Mutations → Winds → Jokers。
- 对应文件见上面的“第二优先级”。
- 每加一个模块就跑一轮固定种子局，确认没有破坏基础逻辑。

1. 洗牌算法修正
   文件：resolve_jokers.gd

之前问题：

1. 直接用 `SetupTiles.setup_tiles` 重建全局布局，导致当前局面的存活牌位置与 ID 映射被破坏。
2. 只按“完全相同 card_id”配对，没走原版 `cardsMatch` 语义（flower 互配、frog/lotus 互配）。

现在改为：

1. 基于“当前存活牌位”创建 dummy 牌库。
2. 在 dummy 上反复抽取 free pair，得到 `pick_order`。
3. 用当前存活牌按 `cardsMatch` 组对后打散。
4. 按 `pick_order` 逆序回填到原位置 ID。
5. 不改坐标拓扑，只改牌内容，避免布局错乱。
6. 主循环触发时机修正
   文件：game_loop.gd

之前问题：

1. 特殊模块在 `deleteTiles` 之前执行。
2. Joker 会在“待删除牌还没删掉前”触发洗牌，随后再删牌，导致状态被二次破坏。

现在改为：

1. 先执行 pre-delete 模块：Dragons / Phoenixes / Mutations。
2. 再 `deleteTiles` + 计分。
3. 再执行 post-delete 模块：Gems / Jokers / Winds。
   这个顺序更贴近原版流程，也能避免 Joker 相关错位和丢牌问题。




每新增一个模块就跑一轮固定种子局，逐阶段验证是否破坏基础逻辑。

脚本位置

- module_regression_runner.gd

脚本行为

1. 固定种子：`20260319`
2. 按顺序累进启用模块：

- dragons
- dragons + phoenixes
- dragons + phoenixes + gems
- dragons + phoenixes + gems + mutations
- dragons + phoenixes + gems + mutations + winds
- dragons + phoenixes + gems + mutations + winds + jokers

3. 每个阶段运行一整局，输出：

- 阶段模块列表
- steps
- points
- end_condition
- fail_reason

4. 通过标准：

- 不出现 invalid 选择
- 循环可终止
- 结束条件是 empty-board 或 no-pairs



# 7.复现回合系统（roguelike 外循环）

- 先迁移 round 生成与难度曲线：来自 runState.tsx。
- 再迁移商店条目生成、购买、升级合成（3 合 1 链路）。
- 阶段切换按 run.tsx 的 stage 状态机做。

# 8.做持久化

- 原项目状态是持久化的（run/game/deck/tile 各自独立）。
- Godot 里建议一份 SaveData 管 run、当前 round、deck、tileDb。
- 存档触发点：进入新阶段、回合结束、购买后。

# 9.最后补表现层

- 动画、音效、tutorial、视觉细节最后做。
- 你当前 Godot 里已有启动脚本可复用入口：start_menu.gd。
