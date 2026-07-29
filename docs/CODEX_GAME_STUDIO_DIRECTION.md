# Codex Game Maker 迁移方向文档

> 历史方向文档。当前已实现的 player-ready 与 commercial workflow 以 `codex-game-studio/references/workflows/` 中的 catalog 和可执行 gate 为准。

研究对象：`https://github.com/Donchitos/Claude-Code-Game-Studios`  
本地研究副本：`.research/Claude-Code-Game-Studios`  
研究版本：`a1697d6`，2026-05-02，源项目当前规模为 49 agents、72 skills、12 hooks、11 path-scoped rules、38 templates。

## 1. 源项目结论

Claude Code Game Studios 本质上不是一个游戏运行时代码框架，而是一套“AI 游戏工作室操作系统”。它把单个 Claude Code 会话包装成一个有层级、有流程、有质量门禁的虚拟工作室。

它由五类东西组成：

1. **Agents**：创意总监、技术总监、制作人、主程、系统设计师、玩法程序、UI 程序、QA 等角色定义。
2. **Skills / Workflows**：源项目用 `/start`、`/brainstorm`、`/gate-check` 等 slash command 做入口；Codex 版改成自然语言触发的 skills。
3. **Hooks**：会话开始、提交前、push 前、写入资产后、上下文压缩前后、agent 审计等自动检查。
4. **Rules**：按路径生效的编码和文档规则，例如 `src/gameplay/**` 必须数据驱动，`src/ui/**` 不能直接改游戏状态。
5. **Templates / Registries**：GDD、ADR、UX spec、sprint plan、release checklist、workflow catalog、traceability registry 等模板和清单。

它最关键的思想有三个：

1. **文件是记忆，不是对话**  
   `production/session-state/active.md` 是持续检查点。多轮设计和实现不依赖聊天历史，而是持续落盘。

2. **先设计，再实现**  
   GDD -> ADR -> Control Manifest -> Epic -> Story -> Implementation -> Review -> Done。代码必须能追溯到设计需求和架构决策。

3. **团队协作是流程，不是自动驾驶**  
   源项目强调 Question -> Options -> Decision -> Draft -> Approval。AI 提供专业结构，人类做最终决策。

## 2. Codex 版本的核心判断

Codex 版本不能逐字搬 `.claude/`，因为 Claude Code 的这些能力和 Codex 的能力边界不完全一样。

| Claude 机制 | Codex 迁移方式 |
|---|---|
| `.claude/agents/*.md` 自定义 subagent 类型 | 转成 `references/agents/*.md` 角色档案。需要并行时用 Codex sub-agent，并在 prompt 中加载对应角色档案。默认不要为每个角色都创建运行时 agent。 |
| `.claude/skills/*/SKILL.md` slash commands | 转成 Codex skills。暂时不做 slash commands；用 `name + description` 和自然语言触发，正文要更短，长内容放 `references/`。 |
| `AskUserQuestion` | Codex 默认用普通对话提出 2-3 个选项；如果当前模式有 `request_user_input`，再使用结构化输入。 |
| `TodoWrite` | 使用 Codex 的 `update_plan`。 |
| `Task` | 只有用户明确要求 team、delegation、parallel agent work，或运行 `team-*` 这类明确团队技能时才使用 sub-agent。普通流程用主 Codex 执行。 |
| `Write/Edit` | Codex 代码改动优先用 `apply_patch`。 |
| Claude hooks | MVP 阶段不要依赖运行时 hooks。改成显式 `scripts/guards/*`、可选 git hooks，以及 skill 内的 preflight/checklist。 |
| statusline | 改成 `game-studio-status` skill 或 `scripts/status.ps1/sh`，不要作为首版核心依赖。 |
| WebSearch | 使用 Codex web 工具。技术/版本问题优先官方文档。 |
| 模型分层 Opus/Sonnet/Haiku | 改成任务复杂度策略：普通实现用当前 Codex，复杂总览可建议高 reasoning；轻量状态检查用短流程。 |

结论：Codex 版应该做成 **模板仓库 + 可选 Codex plugin/skills 包**，而不是只做一个 `.codex` 目录的静态复制。

补充约束：

1. **Agent 少而有用**：首版不追求 49 个角色阵势。只保留 6 个会在日常流程里反复派上用场的核心角色视角：Creative、Game Design、Art、Technical、Production、QA。默认作为 review lens 使用，不把它们都变成运行时 sub-agent。
2. **主动使用 Web Search**：用户对生成资产不满意、资产需求过多需要找参考/素材、引擎版本和本地知识不匹配、Godot API/插件/导出问题不确定时，必须搜索网络；引擎和库问题优先官方文档，资源参考优先官方素材库、开源授权资源、项目主页和可信教程。
3. **Godot 优先**：每次进入设计、架构、资产或实现流程前，先检测当前项目文件判断引擎。空白项目默认推荐 Godot + Web 导出路线；不要把 Phaser、Three.js、PixiJS 作为默认路线，只有用户明确要纯 Web 技术栈或项目已经是这些栈时才使用。

## 3. 建议的 Codex Game Maker 目录结构

建议项目根目录：

```text
AGENTS.md                         # 可选：项目级 Codex 行为约定，保持短
docs/
  CODEX_GAME_STUDIO_DIRECTION.md  # 本文档
src/                              # 游戏源码
assets/
  generated/                      # AI 生成后确认采用的资产
  source-prompts/                 # 每个资产的 prompt 和版本记录
  data/                           # 玩法数据
design/
  gdd/
  art/
  ux/
docs/architecture/
production/
  session-state/active.md
  epics/
  sprints/
  playtests/
tools/
  guards/
  image-pipeline/
codex-game-studio/
  .codex-plugin/plugin.json       # 如果做成本地插件
  skills/
    game-studio-start/
    game-studio-design/
    game-studio-art-assets/
    game-studio-sprite-assets/
    game-studio-map-assets/
    game-studio-asset-qa/
    game-studio-architecture/
    game-studio-review/
  references/
    agents/
    rules/
    templates/
    workflows/catalog.yaml
  scripts/
    guards/
    status/
```

## 4. Skill 迁移策略

不建议首版直接搬 72 个 skills。Codex skills 的触发依赖描述字段，过多细粒度 skill 会让维护成本和触发歧义变高。

首版建议压缩成少量高价值 skills，确保每个都能派上用场。资产生成已经证明是核心能力，所以在原 5 个主流程 skill 之外，额外拆出 3 个资产细分 skill：

| Codex skill | 覆盖源项目命令 | 作用 |
|---|---|---|
| `game-studio-start` | `/start`、`/help`、`/project-stage-detect`、`/adopt` | 新项目引导、现有项目体检、阶段识别。 |
| `game-studio-design` | `/brainstorm`、`/map-systems`、`/design-system`、`/quick-design`、`/review-all-gdds` | 从概念到系统 GDD。 |
| `game-studio-art-assets` | `/art-bible`、`/asset-spec`、`/asset-audit` | 美术圣经、资产规划、GPT Image 2 资产方向。 |
| `game-studio-sprite-assets` | sprite sheet、角色动画、FX、prop pack | 透明帧、GIF 预览、metadata、Godot AnimatedSprite2D/Sprite2D 对接。 |
| `game-studio-map-assets` | 地图、parallax、props、collision/zones | 可玩地图资产拆层、碰撞/区域 metadata、Godot scene 对接。 |
| `game-studio-asset-qa` | 资产质量门禁 | alpha、chroma-key 残留、帧数、裁切、Godot import readiness。 |
| `game-studio-architecture` | `/setup-engine`、`/create-architecture`、`/architecture-decision`、`/create-control-manifest` | 引擎选择、架构、ADR、控制清单。 |
| `game-studio-review` | 源项目的 `/design-review`、`/code-review`、`/gate-check`、`/qa-plan`、`/smoke-check` | 六角色检查、QA gate、playtest evidence。 |

后续如果发现某个 workflow 过大，再拆。例如 production/story 可二期从 `game-studio-review` 和 `game-studio-architecture` 之间拆出。

## 5. Agent 迁移策略

源项目有 49 个角色。Codex 版不应该把它们都做成真实运行时 agent。首版只保留 6 个核心角色视角，保证每个都在流程里有固定职责：

| 角色视角 | 固定用途 |
|---|---|
| Creative | 概念、玩家幻想、支柱、差异化是否成立。 |
| Game Design | 核心循环、系统规则、数值、MVP 边界。 |
| Art | 视觉身份、资产清单、生成图是否符合 art bible。 |
| Technical | Godot/引擎适配、架构、实现风险、版本/API 核查。 |
| Production | 里程碑、scope、下一步优先级。 |
| QA | 可玩性验证、验收标准、测试/evidence。 |

### 5.1 角色档案

把 `.claude/agents/*.md` 压缩为一个短文件：

```text
references/agents/
  core-agent-roster.md
```

每个角色档案只保留：

1. 职责边界。
2. 何时使用。
3. 输出格式。
4. 不允许做什么。
5. 与其他角色的升级关系。

去掉 Claude 专属字段：`tools`、`model`、`maxTurns`、`memory`、`disallowedTools`、`AskUserQuestion` 参数细节。

### 5.2 默认单体工作流

大多数时候 Codex 主 agent 读取角色档案后，以“角色审查清单”的形式执行。例如 `gate-check` 可以在主流程中模拟这些视角：

```text
Creative risk:
Game design risk:
Technical risk:
Production risk:
Art/asset risk:
QA risk:
```

这样比每次都 spawn 多个 agent 更快、更省上下文。

### 5.3 显式团队模式

只有这些场景使用 Codex sub-agent：

1. 用户明确说“让多个 agent / 并行 / 团队一起做”。
2. 用户调用 `team-*` 类型 workflow。
3. 任务天然可并行，且写入范围不重叠。

Codex 版 team skill 应明确声明写入范围。例如：

```text
Worker A: 只改 src/gameplay/combat/** 和 tests/gameplay/combat/**
Worker B: 只改 assets/generated/combat/** 和 design/assets/**
Worker C: 只做只读 QA/review，不写文件
```

## 6. GPT Image 2 资产管线是 Codex 版的差异化重点

这是 Codex Game Maker 相比 Claude 版最值得新增的部分。

源项目已有 `art-bible` 和 `asset-spec`，但没有把 AI 图像生成做成一等管线。Codex 版应该把资产生成纳入设计追踪，而不是随手出图。

### 6.1 新增资产生命周期

```text
Art Bible
  -> Asset Brief
  -> Image Prompt Spec
  -> Draft Generation
  -> Human Pick
  -> Post-process / Slice / Atlas
  -> Import Manifest
  -> In-game Verification
```

### 6.2 建议文件

```text
design/art/art-bible.md
design/assets/asset-manifest.md
design/assets/prompts/<asset-id>.md
assets/generated/<category>/<asset-id>-v001.png
assets/generated/<category>/<asset-id>-v002.png
assets/source-prompts/<asset-id>.yaml
assets/import-manifest.yaml
```

### 6.3 每个生成资产必须记录

```yaml
asset_id: ui_inventory_slot_icon
category: ui/icon
intended_use: Inventory slot icon
source_design:
  art_bible: design/art/art-bible.md
  ux_spec: design/ux/inventory.md
prompt: |
  ...
negative_constraints:
  - no text
  - no watermark
selected_output: assets/generated/ui/ui_inventory_slot_icon-v002.png
status: approved
notes: Human selected v002 because silhouette reads best at 32px.
```

### 6.4 生成规则

1. 项目资产优先走 Codex 内置 image generation 能力。
2. 生成后必须移动或复制到项目 `assets/generated/`，不能只留在 Codex 默认生成目录。
3. 透明图首选“纯色 chroma-key 背景 + 本地抠图”流程；真正模型原生透明需要用户明确确认 CLI fallback。
4. UI 图标、sprite、道具、角色头像要有尺寸、用途、读屏距离、透明/非透明要求。
5. 资产进入游戏前必须有 import manifest，避免代码引用散落的临时文件。
6. 对 Web/HTML5 小游戏，生成资产后要跑浏览器视觉检查，确认不是空白、尺寸不糊、没有 UI 遮挡。

## 7. Codex 版引擎路线

Claude 源项目重点覆盖 Godot、Unity、Unreal。Codex 版保留三大引擎识别，但默认策略改成 **Godot 优先**。

默认决策：

| 项目状态 | 推荐 |
|---|---|
| 空白目录 | Godot 4.7.1 + Web 导出路线。 |
| 已有 `.godot` / `project.godot` | 沿用 Godot。 |
| 已有 Unity/Unreal 工程文件 | 沿用现有引擎，不强行迁移。 |
| 已有 Web 技术栈 | 沿用现有栈，但不主动推荐 Phaser/Three/Pixi。 |
| 用户明确要求浏览器原型 | 优先 Godot Web export；只有明确要求纯 Web 技术栈时才考虑 Phaser/Three/Pixi。 |

Godot-first prototype lane：

```text
/prototype-godot-web
  -> detect existing engine files
  -> choose Godot if blank
  -> generate visual style board
  -> create minimal Godot scene/project plan
  -> export or plan Web build
  -> browser verification when a build exists
```

这条路线适合“更好玩的游戏”快速试错：先用 Godot 做可玩的核心循环，再通过 Web export 给人试玩。

## 8. Hook 与规则的 Codex 改造

### 8.1 首版不要依赖自动 hook

Claude 的 `.claude/settings.json` 把 hooks 绑定到工具事件。Codex 版首版更稳的做法：

```text
tools/guards/check-design-docs.ps1
tools/guards/check-json.ps1
tools/guards/check-hardcoded-gameplay-values.ps1
tools/guards/check-assets.ps1
tools/guards/check-story-readiness.ps1
```

然后在对应 skill 里显式调用。

### 8.2 可选 git hooks

二期可以提供：

```text
.githooks/pre-commit
.githooks/pre-push
tools/install-git-hooks.ps1
tools/install-git-hooks.sh
```

但它应是可选安装，不应该成为模板启动门槛。

### 8.3 Path rules

源项目的 rules 很有价值，应直接保留并改写成 Codex 可读参考：

```text
codex-game-studio/references/rules/gameplay-code.md
codex-game-studio/references/rules/ui-code.md
codex-game-studio/references/rules/network-code.md
codex-game-studio/references/rules/design-docs.md
...
```

每个 production/review skill 根据 touched files 读取对应 rules。

## 9. 工作流保留方案

保留源项目 7 阶段主线：

```text
Concept
  -> Systems Design
  -> Technical Setup
  -> Pre-Production
  -> Production
  -> Polish
  -> Release
```

但 Codex 版应新增两个横向轨道：

1. **Image Asset Track**  
   贯穿 Concept 到 Polish，用于风格探索、角色/道具/UI 资产生成、资产审查。

2. **Playable Prototype Track**  
   贯穿 Pre-Production 到 Production，优先用 Godot 4.7.1 项目和导出预设验证 fun factor。

建议阶段门禁：

| Gate | Codex 版新增检查 |
|---|---|
| Concept -> Systems Design | 是否有 Visual Identity Anchor；是否有首批 style references 或 generated mood samples。 |
| Systems Design -> Technical Setup | GDD 是否能导出资产需求；关键 mechanics 是否有 prototype hypothesis。 |
| Technical Setup -> Pre-Production | 是否选定 Godot 4.7.1 或已有引擎；是否有 asset import policy。 |
| Pre-Production -> Production | 是否有可玩的 vertical slice；AI 资产是否已进入 manifest，而不是临时文件。 |
| Production -> Polish | Godot/editor/export 验证；核心循环试玩证据；没有未追踪生成资产。 |
| Polish -> Release | 资产授权/来源记录完整；发布构建可重复。 |

## 10. 推荐实施里程碑

### Milestone 1：Codex 模板骨架

产出：

```text
codex-game-studio/.codex-plugin/plugin.json
codex-game-studio/skills/game-studio-start/SKILL.md
codex-game-studio/references/workflows/catalog.yaml
codex-game-studio/references/templates/*
codex-game-studio/scripts/guards/detect_engine.ps1
production/session-state/active.md
```

验收：

1. 用户说“开始一个游戏项目”，Codex 能识别阶段并给出下一步。
2. 用户已有旧项目，Codex 能输出 adoption plan。

### Milestone 2：设计与架构闭环

产出：

```text
game-studio-design
game-studio-architecture
references/agents/{creative-director,technical-director,producer,game-designer,lead-programmer}.md
references/rules/*
```

验收：

1. 能生成 `design/gdd/game-concept.md`。
2. 能生成 `design/gdd/systems-index.md`。
3. 能生成 `docs/architecture/adr-*.md` 和 `control-manifest.md`。

### Milestone 3：GPT Image 2 资产管线

产出：

```text
game-studio-art-assets
design/art/art-bible.md
design/assets/asset-manifest.md
assets/source-prompts/*.yaml
tools/image-pipeline/*
```

验收：

1. 能从 art bible 生成可复用 prompt spec。
2. 生成图像会保存进 workspace。
3. 每个采用资产有 prompt/provenance 记录。

### Milestone 4：生产 story 与代码实现

产出：

```text
game-studio-review
tools/guards/*
```

验收：

1. 能从 GDD + ADR 生成小步实现计划。
2. 能实现小步功能，并写测试或手动 evidence。
3. `game-studio-review` 能逐条验证 acceptance criteria。

### Milestone 5：Team workflows 与 Godot 导出验证

产出：

```text
game-studio-teams
Godot export verification checklist
optional team workflow references
```

验收：

1. 用户明确请求团队/并行时，Codex 能拆分不冲突写入范围。
2. Godot CLI 可用时，能验证主场景、导入和 Web/native export preset。

## 11. 风险与取舍

| 风险 | 处理 |
|---|---|
| 72 个 skill 全量迁移导致触发混乱 | 首版保留 5 个主流程 skills，只为核心资产管线拆出 3 个细分 skills，成熟后再按真实需求拆。 |
| 49 个 agent 运行时成本过高 | 首版做角色档案，只有 team workflow 才 spawn。 |
| Claude hook 无法一比一复刻 | 改为显式 guard scripts + 可选 git hooks。 |
| GPT Image 2 输出不可控 | 用 asset brief、prompt spec、human pick、manifest 管资产。 |
| 生成资产堆积污染项目 | 所有采用资产必须进入 `asset-manifest.yaml`，未采用草稿进临时目录或清理。 |
| 过度流程化拖慢做游戏 | 默认 review mode 设为 `lean`，jam/prototype 可用 `solo`。 |

## 12. 下一步建议

建议先不要直接全量移植。第一步应建立一个最小可用 Codex Game Maker：

1. 搭 `codex-game-studio` 插件/技能目录。
2. 先写 `game-studio-start`、`game-studio-design`、`game-studio-art-assets`、`game-studio-architecture`、`game-studio-review` 五个主流程 skills，再补 `game-studio-sprite-assets`、`game-studio-map-assets`、`game-studio-asset-qa` 三个资产核心 skills。
3. 从源项目迁移模板：`game-concept.md`、`game-design-document.md`、`art-bible.md`、`asset-spec.md`、`architecture-decision-record.md`。
4. 把 source agents 压缩成 6 个核心角色视角，写入 `core-agent-roster.md`。
5. 做一个端到端 demo：从一句游戏想法 -> kickoff brief -> game concept -> art bible -> Godot architecture -> QA gate。

这个 demo 跑通后，再决定是否拆出 production/team workflow。这样能尽快验证 Codex + GPT Image 2 + Godot 4.7.1 的核心优势，而不是先陷入 72 个命令的机械搬运。


