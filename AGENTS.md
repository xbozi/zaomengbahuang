# AGENTS.md

本文件为 AI 编码助手在本仓库中工作的项目级指引。

## Project Overview

- 这是一个 Godot 4.1 项目，配置文件为 `project.godot`。
- 主场景：`res://Scene/Main_menu/Main_Menu.tscn`。
- 脚本语言以 GDScript 为主，仓库中包含大量 `.gd`、`.tscn`、`.tres`、`.gdshader` 和资源导入文件。
- 项目使用多个 autoload 单例，见 `project.godot` 的 `[autoload]` 段，例如 `Global`、`BaseHit`、`RoleProp`、`PlayerData`、`AE`、`PoolManager`、`Signals` 等。

## Repository Layout

- `project.godot`: Godot 项目配置、主场景、输入映射、autoload 和渲染设置。
- `Scene/`: 主要场景文件，按功能拆分，例如 `Main_menu`、`Hero`、`Level`、`Monster`、`Shop`、`Skill`、`BackPack`。
- `Script/`: 主要 GDScript 逻辑，结构与 `Scene/` 大体对应。
- 根目录 `.gd`: 全局或 autoload 脚本，例如 `Global.gd`、`AllEquipment.gd`、`CK.gd`、`Signals.gd`。
- `Art/`, `Music/`, `Font/`: 美术、音频、字体资源及其 `.import` 文件。
- `Shader/`: Godot shader 文件。
- `addons/`: Godot 插件目录。
- `godot/`: Godot 生成的本地缓存/导入产物。除非明确需要，不要手动修改。
- `.tools/`: 本地工具目录，已在 `.gitignore` 中忽略。

## Development Commands

本仓库没有检测到独立的包管理器或测试框架配置。优先使用 Godot 编辑器打开项目并运行主场景。

如果本机已安装 Godot CLI，可使用：

```powershell
godot --path . --editor
godot --path .
```

若可执行文件名是 `godot4` 或完整路径，请替换命令中的 `godot`。

常用检查：

```powershell
git status --short
rg -n "TODO|FIXME|push_error|assert" -g "*.gd"
```

## Coding Guidelines

- 遵循现有 GDScript 风格：使用 tab 缩进，保留现有大小写、命名和中英文混用方式。
- 新增脚本时优先放入与功能相匹配的 `Script/<Feature>/` 目录；对应场景放入 `Scene/<Feature>/`。
- 修改公共基类和 autoload 单例前，先搜索调用点。重点关注：
  - `Script/Base/`
  - `Global.gd`
  - `AllEquipment.gd`
  - `Script/MemoryClass/`
  - `Signals.gd`
- 不要随意重命名节点、资源路径、输入映射或 autoload 名称。Godot 场景和脚本常通过字符串路径、节点名、单例名相互引用。
- 大规模数据表或配置列表尽量保持原有结构，避免无关格式化，减少 `.tscn`、`.tres` 和大 `.gd` 文件的噪音 diff。
- 使用 `preload("res://...")` / `load("res://...")` 时保持 Godot 资源路径格式，不要改成系统路径。
- 对战斗、掉落、技能、存档、背包等共享逻辑做改动时，尽量添加最小范围的运行验证说明。

## Scene And Asset Guidelines

- 优先通过 Godot 编辑器修改 `.tscn`、`.tres`、导入设置和项目设置；手写这些文件前先确认改动很小且格式明确。
- 不要删除 `.import` 文件，除非对应源资源也被明确移除。
- 不要手动编辑 `godot/imported/`、`godot/shader_cache/` 等缓存产物。
- 添加图片、音频、字体后，需要在 Godot 中重新导入并确认生成的 `.import` 文件符合预期。

## Verification Checklist

完成改动前至少执行：

```powershell
git status --short
```
改动后不要启动项目；除非我主动要求

根据改动范围再做以下验证：

- 脚本逻辑改动：在 Godot 中运行主场景，观察控制台是否有解析错误或运行时错误。
- 场景/资源改动：在 Godot 编辑器中打开相关场景，确认节点路径、脚本引用、纹理和音频资源未丢失。
- 输入/项目配置改动：检查 `project.godot` 中对应段落，并实际运行一次入口场景。

## Git And Editing Safety

- 不要还原或覆盖用户已有改动；开始修改前先看 `git status --short`。
- 不要执行 `git reset --hard`、批量删除、批量移动资源等破坏性操作，除非用户明确要求。
- 避免无关重排、全文件格式化或编码转换。项目中含有中文资源名和文本，编辑时注意保留原文件编码。
- 提交或汇报时说明实际验证过的内容；如果无法运行 Godot，也要明确说明原因。
