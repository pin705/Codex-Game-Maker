# Codex Game Maker

**Languages:** [English](README.md) | [简体中文](README.zh-CN.md)

![Codex Game Maker banner](assets/brand/banner.png)

**面向 Codex 的 Godot 优先游戏制作工作流，重点支持可进游戏的 2D 资产和可验证原型。**

**快速跳转：** [安装](#快速开始) · [资产流程](#gpt-image-资产流程) · [引擎支持](#引擎支持) · [Skills](#当前包含) · [专业功能](#专业功能) · [安全与门禁](#安全与门禁) · [提示词](#示例提示词) · [路线图](#路线图)

> 当前状态：`v0.1-alpha`。核心工具已经能跑，但仍是早期预览版。

Codex Game Maker 会把一个 Codex 会话变成轻量游戏制作空间：项目启动、引擎检测、Godot 4.4 安装/注册、sprite/map 资产处理、Godot 导入、轻量 production/review gate，以及可显式开启的专业流程。

## 它有什么不同

| 方向 | 说明 |
|---|---|
| Godot 优先 | 空白项目默认推荐 Godot 4.4 + Web export。 |
| 资产可进游戏 | GPT Image 的图不会停在“好看”，而是进入透明帧、GIF、metadata、QA、Godot import。 |
| 默认流程轻量 | 只有 8 个核心 skills，不做一堆用不上的 agent。 |
| 专业流程显式开启 | release、team pass、hooks、accessibility、localization 等只在明确触发时启用。 |
| 遇到版本/资源问题会查文档 | 引擎版本、API、Web export、资源生成不满意时优先查官方文档和网络资源。 |

## 当前包含

| 类别 | 数量 | 说明 |
|---|---:|---|
| 核心 skills | 8 | start、design、art、sprite、map、asset QA、architecture、review |
| 工具脚本 | 29 | 安装、注册、导出、预览、资产处理、gate、hook、import |
| gate 脚本 | 7 | engine、asset、story、production、release、Godot lint、review |
| 模板 | 30 | GDD、art、asset、story、production、release、QA、import manifest |
| 资产处理脚本 | 2 | pixel processor + workflow coordinator |
| Pro aliases | 10 | `/release`、`/team-*`、`/audio-pass`、`/localization-pass` 等 |

## 引擎支持

| 引擎 / 技术栈 | 支持等级 | 当前能力 |
|---|---:|---|
| Godot 4.4 | 一等支持 | 检测、安装/注册、Web 导出、浏览器预览、GDScript lint、sprite 导入、map 场景导入 |
| Phaser / Three.js / PixiJS / HTML canvas | 基础适配 | 能识别并尊重已有 Web 项目；空白项目仍默认推荐 Godot |
| Unity | 检测与接管 | 能识别并保留已有 Unity 项目；暂时没有 Unity 专业流程 |
| Unreal | 检测与接管 | 能识别并保留已有 Unreal 项目；暂时没有 Unreal 专业流程 |

## 快速开始

```powershell
git clone https://github.com/0xnickmortal/Codex-Game-Maker.git my-game
cd my-game
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
```

macOS/Linux:

```bash
pwsh -File tools/check-install.ps1
```

然后在 Codex 里说：

```text
Use Codex Game Maker to start this game project.
```

## Godot

安装 Godot 4.4 和 Web 导出模板：

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-godot.ps1 -WithExportTemplates
```

如果本机已经有 Godot，可以注册已有路径：

```powershell
powershell -ExecutionPolicy Bypass -File tools\register-godot.ps1 -GodotPath "F:\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64"
```

浏览器预览：

```powershell
powershell -ExecutionPolicy Bypass -File tools\preview-godot-web.ps1 -Project . -CreatePresetIfMissing
```

## GPT Image 资产流程

```text
自然语言需求
  -> action bundle / map spec
  -> GPT Image raw sheet 或地图素材
  -> 去背景 / 切帧 / 对齐
  -> 透明 PNG / GIF / pipeline-meta.json
  -> asset QA / 自动修复
  -> Godot SpriteFrames / AnimatedSprite2D / editable level scene
  -> Godot Web 预览
```

创建多动作角色：

```powershell
powershell -ExecutionPolicy Bypass -File tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt"
```

处理 raw sheets：

```powershell
powershell -ExecutionPolicy Bypass -File tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt" -ProcessExistingRaw
```

QA、修复、导入 Godot：

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\repair-asset-processing.ps1 -Root . -Apply
powershell -ExecutionPolicy Bypass -File tools\import-sprite-to-godot.ps1 -Project . -BundleId hero-cat
```

## 它能生成什么

- 玩家、敌人、NPC、召唤物、怪物、动画道具。
- idle、walk、run、jump、attack、hurt、death、cast 等动作。
- projectile、impact、muzzle flash、dust、spell、hit FX。
- reference-guided variants 和 identity-locked actions。
- prop packs、透明 props、layered maps。
- collision、zones、exits、checkpoints、placement metadata。
- Godot `AnimatedSprite2D`、`SpriteFrames`、`Sprite2D`、`StaticBody2D`、`Area2D`、`TileMapLayer` 交接文件。

## 输出文件

典型 sprite action：

```text
raw-sheet-clean.png
sheet-transparent.png
frames/frame-000.png
animation.gif
pipeline-meta.json
asset-manifest.yaml entry
source prompt/provenance file
```

Godot bundle：

```text
resources/animations/<bundle-id>_spriteframes.tres
scenes/characters/<bundle-id>.tscn
design/assets/godot-import-manifest.yaml
```

## 专业功能

专业流程默认不启用，需要显式触发：

| 别名 | 状态 | 用途 |
|---|---:|---|
| `/release` | 可用 | 发布 checklist、changelog、patch notes、release gate |
| `/hotfix` | 可用 | 紧急修复流程 |
| `/hooks-on` | 可用 | 安装可选 professional git hooks |
| `/team-ui` | 规划中 | UI/UX 专项流程 |
| `/team-level` | 规划中 | 关卡专项流程 |
| `/team-combat` | 规划中 | 战斗专项流程 |
| `/audio-pass` | 规划中 | 音频规划 |
| `/narrative-pass` | 规划中 | 叙事检查 |
| `/localization-pass` | 规划中 | 本地化检查 |
| `/accessibility-pass` | 规划中 | 无障碍检查 |

## 示例提示词

```text
Use Codex Game Maker to start a small cozy platformer. Ask at most three important questions, then proceed with reasonable defaults.
```

```text
Use Codex Game Maker to create a cute cat platformer hero with idle, run, jump, attack, and hurt animations.
```

```text
/release Prepare this Godot Web demo for a public alpha release.
```

## 安全与门禁

常用检查：

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-review-gate.ps1 -Root .
```

这些 gate 用来检查工具完整性、资产可用性、Godot 脚本风险、story/smoke evidence 和发布前基本质量。

## 路线图

近期重点：

- 真实资产驱动的猫猫平台跳跃 showcase。
- Demo GIF 和流程图。
- macOS/Linux smoke tests。
- Godot CLI 验证生成的 `.tres` 和 `.tscn` 可加载。
- 更稳定的 reference-guided identity consistency review。

## License

MIT. See [LICENSE](LICENSE).
