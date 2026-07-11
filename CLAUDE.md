# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Godot 4.1 的 2D 动作 RPG（造梦八荒），西游记题材的横版闯关游戏。本仓库由编译后的 Godot 工程通过 GDRE Tools 反编译还原（见 `gdre_export.log`）——因此代码中存在反编译产物、中英文混用的标识符，以及大量基于字符串路径的耦合。代码、注释、节点名、输入动作、物理层名均中英文混用，请保持这一约定。

- 主场景：`res://Scene/Main_menu/Main_Menu.tscn`
- 入口为 `Loder/Loader.tscn`，会先加载 `res://` 下的 `.pck` 文件再切换到主菜单。
- 渲染器：桌面端 `gl_compatibility`，Web 端 `forward_plus`。视口 940×590。
- 无包管理器，无测试框架。`tests/` 目录存在但为空。

## 开发命令

未配置任何构建/测试工具。通过 Godot 编辑器或命令行操作：

```bash
godot --path . --editor   # 在编辑器中打开项目
godot --path .            # 运行主场景
```

仓库未内置 `godot` 可执行文件——使用本地安装的 Godot 4.1（GDRE 日志提示原版可能使用自定义构建；若脚本加载时报错，可能需要用原版游戏二进制作为导出模板）。**不要主动启动项目**——按 AGENTS.md 要求，除非用户明确要求运行，验证止步于 `git status --short`。

常用检查：
```bash
git status --short
rg -n "TODO|FIXME|push_error|assert" -g "*.gd"
```

## 架构

### Autoload 单例（`project.godot` 的 `[autoload]` 段）

全局状态分布在约 19 个单例中。核心的几个：

| 单例 | 文件 | 职责 |
|---|---|---|
| `Global` | `Global.gd`（44 KB） | 游戏状态、预加载场景（子弹、特效、UI）、buff 标志、关卡/进度追踪。几乎被所有代码引用。 |
| `PlayerData` | `Script/MemoryClass/PlayerData.gd` | `player_data` 的数据结构定义——装备页、背包、关卡解锁、评价分数。`Initialized_Data` 字典是重置模板。 |
| `MemoryClass` | `Script/MemoryClass/MemoryClass.gd` | 加密存读档（`FileAccess.open_encrypted_with_pass`，密钥由 `OS.get_unique_id()` 派生）。存档槽 `Ar1.json`–`Ar6.json`，设置存 `MainGame.json`。 |
| `MainSet` | `Script/MemoryClass/main_set.gd` | 主设置数据，与玩家存档分开持久化。 |
| `RoleProp` | `Script/Base/BaseRoleProperies.gd` | 共享角色属性集（基础属性、装备加成、丹药属性、无双值）。 |
| `AE` | `AllEquipment.gd`（205 KB） | 装备数据库——谨慎修改，diff 噪声极大。 |
| `PoolManager` | `PoolManager.gd` | 按 `res://` 路径做场景实例对象池。池化节点需实现 `reset_for_pool()` 做清理。子弹、伤害数字、血条、特效等应使用 `get_instance`/`recycle_instance`，而非手动 `instantiate`/`queue_free`。 |
| `Signals` | `Signals.gd` | 单个 `_on_Choose_pressed` 信号及重连辅助方法。 |
| `BaseHit`、`AddEffect`、`PaSkill`、`MgW`、`BuffInfomation`、`Ck`、`OtherBuff`、`MainMusic`、`CheckFresh` | 根目录 `.gd` 文件 | 战斗数值、特效、被动技能、法宝、buff 信息、反作弊校验、杂项 buff、音乐、新鲜度标志。 |

### 基类层级（`Script/Base/`）

- `BaseObject`（`CharacterBody2D`）→ `BaseHero`、`BaseMonster`。公共部分：移动、重力、HP/SHp、命中/暴击/未命中标志、状态标志（`is_ice`、`is_DeadLink`、`is_EyeFix` 等）。
- `BaseHero`（`Script/Base/BaseHero.gd`）——玩家角色。`@onready` 节点引用依赖特定的子节点结构（`Action/EffectBody`、`base_damagebox/HurtBox`、`MagicWeapon`、`Buff`、`Bullet`、`WSTimer` 对应无双、`ZhenFa` 对应阵法）。英雄脚本：`Script/Hero/Role1.gd`–`Role_5.gd`（悟空/唐僧/八戒/沙僧/白龙）。
- `BaseMonster`（`Script/Base/BaseMonster.gd`）——敌人。怪物脚本为 `Script/Monster/Monster_1.gd`–`Monster_121+`，各自继承 `BaseMonster`。Boss 技能与掉落表见 `docs/boss_skill_drop_table.md`。
- 其他基类：`BaseRoleProperies`、`BaseAddEffect`、`BaseBuff`、`BaseMagicWeapon`、`BaseStage`、`BaseThroughLevel`、`BasicCreateMonster`。

### 场景/脚本布局

`Scene/` 与 `Script/` 按功能一一对应：`Main_menu`、`Hero`、`Level`、`Monster`、`Shop`、`Skill`、`BackPack`、`MagicWeapon`、`Buff`、`Bullet`、`Pellet`、`Task`、`ArchiveInterface`、`LDL`（关卡下载/加载）、`AllSound`。根目录的 `.gd` 文件是 autoload 脚本。

### 物理层（`project.godot` 的 `[layer_names]` 段）

17 个中文命名的 2D 物理层（环境/角色/怪物/吸血/出口/台阶/……）。碰撞逻辑依赖这些名称——禁止重新编号或重命名。

### 插件

`AS2P`（检查器/节点选择器）、`anti_cheat`（变量完整性校验——见 `addons/anti_cheat/variable`）、`codeandweb.texturepacker`（图集导入器）。三者均在 `[editor_plugins]` 中启用。

## 编码规范（来自 AGENTS.md）

- **Tab 缩进。** 保持现有大小写、中英文混用方式及文件编码。
- 新增脚本放入对应的 `Script/<功能>/` 目录；场景放入 `Scene/<功能>/`。
- 修改公共基类和 autoload 单例前，先搜索调用点——重点关注 `Script/Base/`、`Global.gd`、`AllEquipment.gd`、`Script/MemoryClass/`、`Signals.gd`。
- **禁止重命名** 节点、资源路径、输入动作、autoload 名称、物理层名。Godot 场景通过字符串路径引用这些，重命名会悄无声息地破坏场景。
- 使用 `preload("res://...")` / `load("res://...")`，保持 `res://` 资源路径格式，不要改成系统路径。
- 大数据表（`.tscn`、`.tres`、`AllEquipment.gd`）尽量保持原有结构，避免无关格式化产生噪音 diff。
- 池化场景类型优先用 `PoolManager.get_instance(path)` / `recycle_instance(path, node)`，而非手动 instantiate/free。
- `.tscn`/`.tres`/导入设置优先通过 Godot 编辑器修改，而非手写。

## 场景与资源规范

- 不要删除 `.import` 文件，除非对应源资源也被明确移除。
- 不要手动编辑 `godot/imported/`、`godot/shader_cache/`、`godot/editor/`——这些是重新生成的缓存。
- `.tools/` 是 gitignore 的本地工具目录（Android SDK 等）——不要触碰。

## Git 与编辑安全

- 修改前先看 `git status --short`；不要还原或覆盖用户已有改动。
- 不执行 `git reset --hard`、批量删除/移动、全文件格式化、编码转换，除非用户明确要求。
- 汇报时说明实际验证过的内容。如果无法运行 Godot，也要明确说明。
