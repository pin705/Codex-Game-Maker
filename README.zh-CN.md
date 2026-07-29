# Codex Game Maker

**Languages:** [English](README.md) | [简体中文](README.zh-CN.md)

![Codex Game Maker banner](assets/brand/banner.png)

**面向 Codex 的 Godot 优先端到端游戏工作流：目标是完整、精致、可交给玩家，而不是单屏原型。**

**快速跳转：** [安装与更新](#快速开始) · [Player-Ready 模式](#player-ready-模式) · [商业发布模式](#商业发布模式) · [1.0 范围](#10-范围与证据标准) · [资产流程](#gpt-image-资产流程) · [Skills](#当前包含) · [安全与门禁](#安全与门禁) · [提示词](#示例提示词)

> 当前状态：`v1.0.0`。Godot 优先的商业 2D 工作流、项目 contract、迁移路径与发布工具已经进入稳定版。Gate 通过只代表声明范围内已有当前、可验证的 evidence，不能替代平台认证、法律顾问、签名授权、商店审核、独立视觉判断或真实玩家测试。

Codex Game Maker 会把一个 Codex 会话变成端到端游戏工作室：产品与游戏设计、Godot 实现、完整状态、生产级资产、游戏化 HUD/菜单、控制、音频、自动测试、运行截图、人工 playtest、性能、构建、合规、本地化、无障碍、商店素材、遥测、客服与回滚计划。

## 它有什么不同

| 方向 | 说明 |
|---|---|
| Godot 优先 | 空白项目遵循已验证的版本策略；当前推荐 Godot 4.6.2，并支持 4.6 稳定系列。 |
| 资产可进游戏 | GPT Image 的图不会停在“好看”，而是进入透明帧、GIF、metadata、QA、Godot import。 |
| 端到端负责 | 宽泛的“制作/完成游戏”请求会继续经过玩法、完整状态、资产、UI、音频、测试与 playtest。 |
| 有设计感的呈现 | art bible 统一驱动 HUD、菜单、图标、字体、动效和音频识别。 |
| Evidence gate | 单屏、placeholder、默认控件、网页 dashboard 风格 UI、静音或未测试声明都不能通过 player-ready。 |
| 商业全流程 | 商业目标、平台、性能、合规、本地化、无障碍、营销、在线服务、发布、客服、遥测与回滚最终汇入一个 release contract。 |
| 遇到版本/资源问题会查文档 | 引擎版本、API、Web export、资源生成不满意时优先查官方文档和网络资源。 |

## Player-Ready 模式

“制作这个游戏”“完成这个原型”或“自动从头做到尾”等宽泛请求会进入 `game-studio-build`。除非用户明确只要 prototype，否则默认目标是边界清晰的 `PLAYER_READY` 游戏。

流程不会套用固定的 title/pause/victory 清单。每个游戏都要声明自己的 schema-v2 状态图、transition、required journey、completion/recovery path、experience requirement，以及由该游戏实际系统推导出的资产、UI 和音频 coverage。`player_ready_gate.py` 会阻止 agent 把 mock、空模板或只会启动的场景说成完成。

Gate 会验证 graph reachability、每个 required state 的不同运行证据、每条 journey/recovery 的 executable command、资产 provenance/runtime references、UI surface coverage、动态 audio contract，以及绑定当前项目 fingerprint 的命令日志与哈希。视觉流程会先锁定 look-dev，再检查每个 required state × target viewport 的当前截图、资产比例/九宫格/crop/tile 用法、跨资产风格一致性、未关闭的 High/Blocker，并把截图绑定到真实 visual-smoke command。测试覆盖没有传统状态名的 endless sandbox、错误复用截图、拉伸资产、虚假单候选 look-dev 与未绑定视觉证据。真正的“好玩”和市场审美仍必须由真实玩家测试与有判断力的视觉 review 决定。

## 商业发布模式

`/commercial-release` 会把已通过 player-ready 的候选版本推进为“针对明确平台、语言、商业模式、在线范围与发布层级”的 release candidate，而不是笼统声称一个 build 在所有平台都已商业就绪。

它会增加：

1. 目标用户、市场定位、范围、预算、定价、商业化与 go/no-go 假设。
2. 固定版本的平台 build matrix、可复现导出、artifact hash、签名/公证状态、smoke test 与商店准备度。
3. 目标设备上的 frame time、内存、加载、稳定性与回归预算。
4. 版权/来源、隐私/数据、评级、条款、支付、年龄义务与审批记录。
5. 字符串外置、语言覆盖、字体、溢出截图、语言审校、无障碍符合性与目标设备测试。
6. 真实且版权清晰的商店素材与声明，以及发布运营、遥测/crash、客服、事故响应、回滚和补丁计划。
7. 在适用时验证叙事连续性，以及在线服务的安全、负载、故障、备份与恢复。

跨平台 CLI：

```bash
python3 scripts/cgm.py doctor --root /path/to/game
python3 scripts/cgm.py quality --root /path/to/game
python3 scripts/cgm.py player-ready --root /path/to/game
python3 scripts/cgm.py commercial-release --root /path/to/game
```

法律/评级批准、保密主机认证、商店账号决策、签名凭据与不可逆发布必须由对应授权人完成；插件会把它们保留为 blocker，不会伪造通过。

## 1.0 范围与证据标准

1.0 的核心目标是成为可靠的 **Godot 优先商业 2D 游戏制作工具集**。第一方完成标准覆盖：有明确边界的 2D 玩法、游戏专属玩家旅程、游戏化 UI、2D 资产集成、音频、无障碍、本地化、可复现质量证据，以及针对已声明桌面/Web 平台的发布准备。

以下能力属于条件式或外部协作范围，不是 1.0 对所有项目的无条件承诺：

- 3D 项目可以使用规划、架构、评审、性能、合规和发布 contracts，但完整的第一方 3D 资产与运行时 pipeline 不属于 1.0 核心；需要采用适合项目的外部 3D 工具和专业人员。
- 主机平台需要平台方授权、NDA 内容、许可 SDK、开发机、认证权限与对应负责人。插件可以准备非保密计划和 evidence，但不能完成主机认证或提交。
- 在线服务和后端只在项目明确声明时进入范围。插件可以设计并验证特定供应商的安全、数据、负载、备份、恢复与故障 evidence，但不自带也不代运营托管后端。
- 商店账号、签名/公证凭据、评级、税务/支付设置、平台协议、法律意见与不可逆发布仍由有权限的人负责。

所有证据声明必须保持窄范围并可复现。仓库 validator 和 regression tests 只能证明已声明 contract 与 guardrail 按测试运行；它们不能证明游戏一定好玩、视觉优秀、商业成功、通过认证或获得法律批准。Player-ready 或 commercial PASS 必须绑定当前项目 artifacts，并接受诚实评审。只有在同时公开可复现的 eval 输入、输出、评分规则与 reviewer provenance 时，才应发布 benchmark 或质量结论；计划中的 showcase、自行填写的 PASS、单个成功例子都不能证明普遍质量。

## 当前包含

| 类别 | 数量 | 说明 |
|---|---:|---|
| 核心 skills | 23 | Player-ready 全流程，加 business、commercial release、platform、compliance、performance、localization、accessibility、narrative、online、liveops、marketing |
| 工具脚本 | 32 | 安装、注册、导出、预览、资产处理、gate、hook、import |
| 顶层 Python CLI 脚本 | 7 | 跨平台 orchestrator、quality、已校验 Godot 安装/导出、style lock、audio QA 与 migration |
| gate 脚本 | 9 | engine、asset、story、production、release、Godot lint、review、player-ready、commercial release |
| 模板 | 60 | GDD/art/style/session/UI/audio、结构化视觉质量/evidence，以及 business、build、performance、compliance、localization、accessibility、marketing、security、telemetry、liveops |
| 资产处理脚本 | 2 | pixel processor + workflow coordinator |
| 自然语言 aliases | 20 | `/player-ready`、`/commercial-release`、`/quality` 与各专业 pass |

## 引擎支持

| 引擎 / 技术栈 | 支持等级 | 当前能力 |
|---|---:|---|
| Godot 4.6.2 | 推荐 | 跨平台安装/导出、export templates、检测/注册、Web 预览、GDScript lint、sprite/map 导入 |
| Godot 4.6 | 支持 | 使用已验证的最新 patch；发布候选必须固定精确引擎与 export-template 版本 |
| Godot 4.5 | 仅安全/平台修复 | 现有项目可临时保留，但新项目应使用 4.6，商业发布需明确迁移/风险决定 |
| Godot 4.7 开发版 | 不支持生产 | 可以单独评估预发布版本，但不能满足 player-ready 或 commercial 的引擎 gate |
| Phaser / Three.js / PixiJS / HTML canvas | 基础适配 | 能识别并尊重已有 Web 项目；空白项目仍默认推荐 Godot |
| Unity | 检测与接管 | 能识别并保留已有 Unity 项目；暂时没有 Unity 专业流程 |
| Unreal | 检测与接管 | 能识别并保留已有 Unreal 项目；暂时没有 Unreal 专业流程 |

## 快速开始

推荐直接从仓库 URL 安装 plugin：

```bash
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

确认 `codex-game-maker@codex-game-maker` 显示为已安装且启用，然后新建一个 **Codex task**。已经打开的 task 可能继续使用旧的 skills snapshot。

### 更新已安装的 plugin

只刷新 marketplace snapshot 不会重新安装已经缓存的 plugin package。请执行完整流程：

```bash
codex plugin marketplace upgrade codex-game-maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

确认安装版本符合预期，然后新建 Codex task。

### 卸载或回滚

只卸载 plugin、保留 marketplace：

```bash
codex plugin remove codex-game-maker@codex-game-maker
```

如果不再需要这个 marketplace，再单独移除：

```bash
codex plugin marketplace remove codex-game-maker
```

回滚时使用包含 marketplace catalog 的已知可用 Git tag 或 commit：

```bash
codex plugin remove codex-game-maker@codex-game-maker
codex plugin marketplace remove codex-game-maker
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker --ref <known-good-tag-or-commit>
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

卸载或回滚后也要新建 Codex task。操作前先提交或备份游戏项目；移除 plugin 不会迁移或删除此前已经写入项目的文件。

如需开发或验证 plugin source：

```powershell
git clone https://github.com/pin705/Codex-Game-Maker.git
cd Codex-Game-Maker
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1 -Root plugins\codex-game-maker
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/check-install.ps1 -Root plugins/codex-game-maker
```

然后在 Codex 里说：

```text
Use Codex Game Maker to start this game project.
```

对于空文件夹、新项目、或者涉及多个系统/资产/工作流的复杂需求，Codex Game Maker 会使用精简 kickoff：总结需求、检测项目上下文、给出默认方案、最多问 3 个关键问题。回复 `go with defaults and build it player-ready` 后，日常实现、资产、UI 与音频选择会自动继续，不再反复确认。

如果 Codex 环境支持更大的上下文窗口，建议为长期游戏项目使用最大可用上下文，目标是 1M tokens。仓库文件本身不能强制修改真实会话 context，因此 Codex Game Maker 会通过 planning docs、asset manifests 和 `production/session-state/active.md` 保持连续性。

## Godot

在 Windows、macOS 或 Linux 安装版本策略推荐的 Godot 与对应 export templates：

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --with-export-templates
```

只查看下载与安装计划：

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --dry-run
```

兼容 PowerShell 入口：

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-godot.ps1 -WithExportTemplates
```

如果本机已经有 Godot，可以注册已有路径：

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\register-godot.ps1 -GodotPath "F:\Godot_v4.6.2-stable_win64.exe"
```

浏览器预览：

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\preview-godot-web.ps1 -Project . -CreatePresetIfMissing
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
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt"
```

处理 raw sheets：

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt" -ProcessExistingRaw
```

QA、修复、导入 Godot：

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\repair-asset-processing.ps1 -Root . -Apply
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\import-sprite-to-godot.ps1 -Project . -BundleId hero-cat
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
| `/commercial-release` | 可用 | 执行声明平台的完整商业工作流与严格 gate |
| `/quality` | 可用 | 执行 argv 命令并记录带哈希的质量证据 |
| `/release` | 可用 | 准备 build、合规、商店包、发布运营与 go/no-go evidence |
| `/hotfix` | 可用 | 紧急修复流程 |
| `/hooks-on` | 可用 | 安装可选 professional git hooks |
| `/player-ready` | 可用 | 完整 build、polish 与 evidence 循环 |
| `/business-pass` | 可用 | 验证用户、市场、范围、定价、预算、经济模型与 go/no-go 假设 |
| `/team-ui` | 可用 | 游戏化 UI、响应式布局、focus、accessibility 与运行 QA |
| `/team-level` | 可用 | 关卡实现、环境集成、过渡与 playtest |
| `/team-combat` | 可用 | 战斗实现、反馈、平衡、测试与 QA |
| `/audio-pass` | 可用 | 音频清单、制作/来源、集成、混音、设置与监听 QA |
| `/narrative-pass` | 可用 | 叙事状态、dialogue ID、运行分支、连续性与内容 QA |
| `/localization-pass` | 可用 | 字符串外置、字体、语言覆盖、溢出截图与语言审校 |
| `/accessibility-pass` | 可用 | 无障碍检查 |
| `/platform-pass` | 可用 | 分平台导出、打包、签名、hash、smoke test 与商店准备 |
| `/performance-pass` | 可用 | 目标设备性能测量与回归预算 |
| `/compliance-pass` | 可用 | 权利、隐私、评级、支付、数据、条款与外部批准 |
| `/online-pass` | 可用 | 身份、数据、安全、负载、故障、备份与恢复 |
| `/liveops-pass` | 可用 | 遥测、crash、客服、事故、回滚与补丁 |
| `/marketing-pass` | 可用 | 真实、最新、本地化且版权清晰的商店与发布素材 |

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
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
python3 plugins/codex-game-maker/scripts/guards/player_ready_gate.py --root .
python3 plugins/codex-game-maker/scripts/cgm.py commercial-release --root .
```

这些 gate 用来检查工具完整性、资产可用性、Godot 脚本风险、完整状态、游戏化 UI、音频、自动测试、运行 artifacts、人工 playtest，以及商业发布所需的版本化 build、性能、合规、本地化、无障碍、营销、在线服务与 liveops evidence。

## License

MIT. See [LICENSE](LICENSE).
