# 技术架构文档 — 修仙：宗门风云

## 版本

| 字段 | 内容 |
|------|------|
| **版本** | 0.1.0 |
| **日期** | 2026-05-27 |
| **引擎** | Godot 4.6+ |
| **语言** | GDScript |

---

## 一、架构概览

### 分层架构

```
┌─────────────────────────────────────────┐
│              UI Layer (src/ui/)          │
│  MainMenu, SectOverview, DisciplePanel,  │
│  WorldMap, EventLog, AlchemyUI           │
├─────────────────────────────────────────┤
│         Gameplay Layer (src/gameplay/)    │
│  SectController, DiscipleController,      │
│  AlchemyController, EventController,      │
│  CombatController, TimeController         │
├─────────────────────────────────────────┤
│           Core Layer (src/core/)          │
│  autoload/  (5 singletons)               │
│  data/      (8 Resource classes)          │
│  systems/   (pure logic utilities)        │
├─────────────────────────────────────────┤
│           Engine (Godot 4.6+)            │
└─────────────────────────────────────────┘
```

### 数据流向

```
用户输入 → UI Layer → Gameplay Controller → Core Data (Resource)
                                    ↓
                              EventBus (signal)
                                    ↓
                         其他 Controller 订阅响应
```

### 核心原则

1. **数据层纯净化**: Resource 子类不发射信号，不含业务逻辑
2. **控制器中介化**: gameplay 层控制器处理所有业务逻辑和信号发射
3. **EventBus 解耦**: 系统间通过 EventBus 信号通信，禁止直接调用
4. **场景无逻辑**: 场景文件仅包含节点结构和绑定，逻辑在控制器脚本中

---

## 二、autoload 单例设计

### GameManager
- **职责**: 游戏生命周期管理（新游戏/加载/保存）
- **状态**: current_sect (SectData), game_initialized (bool)
- **依赖**: SaveManager（单向调用，传入数据）
- **信号**: 不发射信号，由调用方通过 EventBus 发射

### EventBus
- **职责**: 全局事件中枢，解耦所有系统间通信
- **信号数**: 20+（生命周期/时间/弟子/宗门/资源/生产/事件/外交/战斗）
- **原则**: 信号命名用过去式，参数精简

### TimeManager
- **职责**: 游戏时间推进（月/年），驱动所有时间依赖系统
- **信号**: month_passed, year_passed
- **控制**: pause/resume/speed 调节

### DataRegistry
- **职责**: 静态游戏数据只读注册表
- **内容**: 境界/灵根/设施/丹药/技能定义
- **加载**: _ready() 时从 entities.yaml 或硬编码加载

### SaveManager
- **职责**: 序列化/反序列化，纯工具类
- **API**: save_game(path, data) → bool, load_game(path) → Resource

---

## 三、场景结构

```
scenes/
├── main.tscn                    # 入口场景（autoload 初始化后自动加载）
├── ui/
│   ├── main_menu.tscn           # 主菜单（新游戏/加载/设置/退出）
│   ├── sect_overview.tscn       # 宗门总览（核心主界面）
│   ├── disciple_panel.tscn      # 弟子管理面板
│   ├── facility_panel.tscn      # 设施管理面板
│   ├── alchemy_ui.tscn          # 炼丹界面
│   ├── world_map.tscn           # 世界地图
│   ├── event_dialog.tscn        # 事件弹窗（含选项）
│   ├── diplomacy_panel.tscn     # 外交界面
│   └── game_hud.tscn            # 顶部HUD（时间/资源/通知）
├── world/
│   └── world_map_view.tscn      # TileMap 世界地图视图
└── shared/
    ├── button_components.tscn   # 通用按钮组件
    └── tooltip.tscn             # 通用提示框
```

---

## 四、gameplay 控制器

| 控制器 | 职责 | 关键方法 |
|--------|------|----------|
| **SectController** | 宗门管理（建造/升级/门规/晋升） | build_facility(), upgrade_facility(), promote_rank() |
| **DiscipleController** | 弟子管理（招收/培养/任务分配/关系） | recruit(), assign_task(), check_breakthrough() |
| **AlchemyController** | 炼丹炼器逻辑 | craft_pill(), forge_equipment(), discover_recipe() |
| **EventController** | 事件触发和选项处理 | roll_events(), resolve_choice(), advance_event_chain() |
| **CombatController** | 战斗自动结算 | simulate_battle(), calculate_combat_power() |
| **TimeController** | 时间推进时的批量更新 | process_month(), process_year() — 订阅 TimeManager 信号 |
| **WorldController** | NPC宗门AI和世界状态 | process_npc_turn(), update_world_state() |

### 控制器通信模式

```
// 示例：弟子突破流程
DiscipleController.check_breakthrough(disciple)
    → 计算突破结果
    → 更新 DiscipleData
    → 发射 EventBus.disciple_broken_through(id, realm, sub)
    → SectController 监听 → 检查宗门升级条件
    → EventController 监听 → 可能触发后续事件
```

---

## 五、存档系统

### 存档格式

```json
{
  "version": "0.1.0",
  "timestamp": 1716848000,
  "date_string": "宗门历25年 春 (3月)",
  "name": "青云宗",
  "rank": 8,
  "prestige": 350,
  "spirit_stones": 1200,
  "herbs": {"spirit_herb": 45, "foundation_grass": 3},
  "ores": {"iron": 20, "spirit_iron": 5},
  "facilities": [...],
  "disciples": [...],
  "inventory": [...],
  "pill_recipes": [...],
  "faction_relations": {...},
  "active_decrees": [...],
  "world_state": {
    "year": 25,
    "era": 0,
    "factions": [...],
    "active_events": [...]
  }
}
```

### 存档流程

```
保存:
  GameManager.save_game("slot_01")
    → SaveManager.save_game("slot_01", current_sect)
      → _serialize_sect() → JSON
      → 写入 user://saves/slot_01.json

加载:
  GameManager.load_game(path)
    → SaveManager.load_game(path)
      → 读取 JSON → _deserialize_sect() → SectData
    → current_sect = result
```

---

## 六、性能考量

| 场景 | 策略 |
|------|------|
| 50+ 弟子同时修炼 | 月结算批量处理，不逐帧更新 |
| NPC 宗门 AI (10-15个) | 每年结算一次，复用通用模拟函数 |
| 事件池（100+事件） | 按条件预过滤再随机，不遍历全池 |
| 存档大小 | JSON压缩，预期 < 2MB |
| UI 更新 | 仅在数据变化时更新，用信号驱动 |

---

## 七、安全考量

- 存档文件带版本号，加载时检查兼容性
- 不存储可执行代码（JSON 纯数据）
- 输入验证在 gameplay 层，数据层信任内部调用
- 随机种子可复现（用于调试和bug报告）

---

## 八、依赖关系

```
GameManager → SaveManager, SectData (保存时传入数据，不拉取)
TimeManager → EventBus (emits month_passed/year_passed signals)
TimeController → EventBus (subscribes to TimeManager-emitted signals)
All Controllers → EventBus (emit/subscribe) + DataRegistry (read only)
UI Scenes → GameManager + EventBus (读取状态 + 订阅更新通知)
```

无循环依赖。

---

## ADR 索引

| # | 决策 | 文档 |
|---|------|------|
| ADR-001 | JSON存档方案 vs 二进制 | `docs/architecture/adr-001-save-format.md` |
| ADR-002 | Resource数据层 vs 自定义类 | `docs/architecture/adr-002-data-layer.md` |
| ADR-003 | Control节点UI vs 自定义绘制 | `docs/architecture/adr-003-ui-architecture.md` |
