# 修仙：宗门风云 — Game Studio Agent Architecture

基于 Claude Code Game Studios 框架的修仙门派模拟经营游戏。
49 个协调子代理，按真实游戏工作室层级管理开发流程。

## 技术栈

- **游戏引擎**: Godot 4
- **语言**: GDScript
- **版本控制**: Git (trunk-based development)
- **构建系统**: Godot 内置构建系统

## 项目结构

```
CLAUDE.md                           # 主配置
.claude/                            # 代理定义、技能、钩子、规则、文档
src/                                # 游戏源码 (core, gameplay, ai, ui)
assets/                             # 游戏资产 (art, audio, data)
design/                             # 游戏设计文档 (gdd, narrative, ux, registry)
docs/                               # 技术文档 (architecture, engine-reference)
tests/                              # 测试套件 (unit, integration)
tools/                              # 构建和管线工具
prototypes/                         # 原型 (隔离于 src/)
production/                         # 制作管理 (sprints, milestones, releases)
```

## 引擎版本参考

Godot 4.6+

## 技术偏好

- 数据驱动: 所有游戏数据使用 `Resource` 子类定义
- autoload 单例管理全局状态
- JSON 存档系统
- Control 节点 UI + 水墨/古风主题

## 协作协议

**用户驱动，非自主执行。**
每个任务遵循: 提问 → 选项 → 决策 → 草稿 → 批准

- 写入文件前必须先确认
- 多文件修改需明确批准
- 禁止未经指示的提交

## 编码规范

- 类名: PascalCase (`class_name CultivationData`)
- 函数/变量: snake_case (`func calculate_breakthrough()`)
- 常量: UPPER_CASE (`const MAX_REALM = 9`)
- 信号: 过去式 (`signal disciple_broken_through`)
- 缩进: tab
