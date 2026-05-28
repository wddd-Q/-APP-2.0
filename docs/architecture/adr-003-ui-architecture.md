# ADR-003: UI架构选择

## 状态
已采纳 (2026-05-27)

## 背景
需要决定游戏UI的实现方式。候选方案：Godot Control 节点系统、自定义 Canvas 绘制、第三方 UI 框架。

## 决策
**使用 Godot 内置 Control 节点 + Theme 系统。自定义水墨/古风主题。**

## 评估标准

| 方案 | 开发速度 | 可维护性 | 性能 | 自定义度 |
|------|----------|----------|------|----------|
| Control 节点 | ★★★★★ | ★★★★★ | ★★★★☆ | ★★★★☆ |
| Canvas 绘制 | ★★☆☆☆ | ★★☆☆☆ | ★★★★★ | ★★★★★ |
| 第三方框架 | ★★★☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★☆☆ |

## 理由

1. **开发效率**: Control 节点的容器布局、锚点系统、Theme 系统直接可用
2. **信号系统**: 内置 signal/slot 模式与 EventBus 天然兼容
3. **主题化**: 一个 Theme 资源可统一所有 UI 风格
4. **够用的自定义**: 对于模拟经营游戏，水墨风格通过 Theme + 贴图即可实现

## UI 架构

```
Control 节点树:
GameHUD (MarginContainer)
├── TopBar (HBoxContainer)
│   ├── DateLabel
│   ├── SpiritStonesLabel
│   └── NotificationBadge
├── MainView (TabContainer)
│   ├── SectOverview (宗门总览)
│   ├── DisciplePanel (弟子管理)
│   ├── FacilityPanel (设施管理)
│   ├── AlchemyUI (炼丹炼器)
│   ├── WorldMap (世界地图)
│   └── DiplomacyPanel (外交)
└── EventDialog (Popup — 条件显示)
```

## 后果

- 正向: 标准化UI开发，团队容易上手
- 正向: Theme 切换可实现"皮肤"功能
- 负向: Control 节点树深了以后性能需关注
- 约束: 复杂动画需要用 AnimationPlayer 配合

## 替代方案

**Canvas 绘制**: 放弃了。开发成本太高，且对于模拟经营游戏（菜单/面板为主）没有明显优势。如果未来需要特殊效果（如灵气粒子），可以作为 Control 的叠加层使用。
