# Codex Game Maker

**Languages:** [English](README.md) | [简体中文](README.zh-CN.md)

![Codex Game Maker banner](assets/brand/banner.png)

**面向 Codex 的 Godot 优先端到端游戏工作流：目标是完整、精致、可交给玩家，而不是单屏原型。**

**快速跳转：** [安装](#快速开始) · [Player-Ready 模式](#player-ready-模式) · [资产流程](#gpt-image-资产流程) · [Skills](#当前包含) · [安全与门禁](#安全与门禁) · [提示词](#示例提示词)

> 当前状态：`v0.1-alpha`。核心工具已经能跑，但仍是早期预览版。

Codex Game Maker 会把一个 Codex 会话变成端到端游戏制作空间：设计、Godot 实现、完整状态、生产级资产、游戏化 HUD/菜单、控制、音频、自动测试、运行截图和人工 playtest evidence。

## 它有什么不同

| 方向 | 说明 |
|---|---|
| Godot 优先 | 空白项目默认推荐 Godot 4.4 + Web export。 |
| 资产可进游戏 | GPT Image 的图不会停在“好看”，而是进入透明帧、GIF、metadata、QA、Godot import。 |
| 端到端负责 | 宽泛的“制作/完成游戏”请求会继续经过玩法、完整状态、资产、UI、音频、测试与 playtest。 |
| 有设计感的呈现 | art bible 统一驱动 HUD、菜单、图标、字体、动效和音频识别。 |
| Evidence gate | 单屏、placeholder、默认控件、网页 dashboard 风格 UI、静音或未测试声明都不能通过 player-ready。 |
| 遇到版本/资源问题会查文档 | 引擎版本、API、Web export、资源生成不满意时优先查官方文档和网络资源。 |

## Player-Ready 模式

“制作这个游戏”“完成这个原型”或“自动从头做到尾”等宽泛请求会进入 `game-studio-build`。除非用户明确只要 prototype，否则默认目标是边界清晰的 `PLAYER_READY` 游戏。

流程会覆盖完整玩家旅程、全部可见状态、角色/环境/反馈/UI/品牌资产、Godot 原生主题与菜单、控制器 focus、音频总线与事件、自动 core-loop/long-run 测试、每个状态的运行证据以及人工 playtest。`player_ready_gate.py` 会阻止 agent 把 mock、空模板或只会启动的场景说成完成。

Gate 能强制 coverage 与 evidence；真正的商业审美仍必须查看运行中的游戏并让真实玩家测试，因此流程要求截图、录屏/监听与 playtest 记录，而不是只看代码自我宣称质量。

## 当前包含

| 类别 | 数量 | 说明 |
|---|---:|---|
| 核心 skills | 12 | start、build、design、implementation、art、sprite/map、asset QA、UI/UX、audio、architecture、review |
| 工具脚本 | 32 | 安装、注册、导出、预览、资产处理、gate、hook、import |
| gate 脚本 | 8 | engine、asset、story、production、release、Godot lint、review、player-ready |
| 模板 | 40 | GDD、art、状态/coverage、UI/audio、story、production、release、QA、import manifest |
| 资产处理脚本 | 2 | pixel processor + workflow coordinator |
| Pro aliases | 11 | `/player-ready`、`/release`、`/team-*`、`/audio-pass`、`/localization-pass` 等 |

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

对于空文件夹、新项目、或者涉及多个系统/资产/工作流的复杂需求，Codex Game Maker 会使用精简 kickoff：总结需求、检测项目上下文、给出默认方案、最多问 3 个关键问题。回复 `go with defaults and build it player-ready` 后，日常实现、资产、UI 与音频选择会自动继续，不再反复确认。

如果 Codex 环境支持更大的上下文窗口，建议为长期游戏项目使用最大可用上下文，目标是 1M tokens。仓库文件本身不能强制修改真实会话 context，因此 Codex Game Maker 会通过 planning docs、asset manifests 和 `production/session-state/active.md` 保持连续性。

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
| `/player-ready` | 可用 | 完整 build、polish 与 evidence 循环 |
| `/team-ui` | 可用 | 游戏化 UI、响应式布局、focus、accessibility 与运行 QA |
| `/team-level` | 可用 | 关卡实现、环境集成、过渡与 playtest |
| `/team-combat` | 可用 | 战斗实现、反馈、平衡、测试与 QA |
| `/audio-pass` | 可用 | 音频清单、制作/来源、集成、混音、设置与监听 QA |
| `/narrative-pass` | 规划中 | 叙事检查 |
| `/localization-pass` | 规划中 | 本地化检查 |
| `/accessibility-pass` | 可用 | 无障碍检查 |

## 示例提示词

```text
Use Codex Game Maker to build a small cozy platformer player-ready from start to finish. Go with defaults, continue autonomously, and do not stop at a one-screen prototype or mock assets.
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
python3 codex-game-studio/scripts/guards/player_ready_gate.py --root .
```

这些 gate 用来检查工具完整性、资产可用性、Godot 脚本风险、完整状态、游戏化 UI、音频、自动测试、运行 artifacts、人工 playtest 与发布前质量。

## License

MIT. See [LICENSE](LICENSE).
