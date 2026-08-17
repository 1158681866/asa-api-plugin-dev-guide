# Agent Skill 集成

本仓库以 [Agent Skills 开放格式](https://agentskills.io/specification) 提供 ASA API 插件开发能力。核心规则不绑定 Codex、Claude Code 或任何单一 Agent。

## 单一权威源

```text
skills/asa-api-plugin-dev/
├── SKILL.md
├── references/
└── agents/openai.yaml
```

- `SKILL.md`：跨客户端核心入口。
- `references/`：按任务加载的专题规则。
- `agents/openai.yaml`：可选 OpenAI UI 元数据；其他客户端可以忽略。

平台适配文件不得复制核心规则。根目录 `AGENTS.md` 与 `CLAUDE.md` 只负责自动发现并指向上述 Skill。

## 三种使用方式

### 1. 客户端原生安装

把完整 `asa-api-plugin-dev` 目录安装到客户端声明的 Skills 根目录。Windows 可使用：

```powershell
.\scripts\install-skill.ps1 -SkillsRoot '<agent-skills-root>'
```

目标存在时默认失败；`-Replace` 会先备份再替换。不要猜目标路径，先查看客户端当前文档。

当前常见的共享位置是用户级 `~/.agents/skills` 或项目级 `.agents/skills`，Codex、Gemini CLI、Cursor、GitHub Copilot 等客户端可以从中发现 Skill。Claude Code 使用 `~/.claude/skills` 或 `.claude/skills`，优先通过目录符号链接指向同一份 `.agents/skills/asa-api-plugin-dev`，避免复制后漂移；Windows junction 仅作为客户端实测可发现后的兼容后备。

Windows 用户可以先安装统一副本，再单独创建 Claude 目录符号链接：

```powershell
$agentsRoot = Join-Path $HOME '.agents\skills'
& .\scripts\install-skill.ps1 -SkillsRoot $agentsRoot

$commonSkill = Join-Path $agentsRoot 'asa-api-plugin-dev'
$claudeRoot = Join-Path $HOME '.claude\skills'
$claudeSkill = Join-Path $claudeRoot 'asa-api-plugin-dev'
New-Item -ItemType Directory -Path $claudeRoot -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $claudeSkill -Target $commonSkill
```

如果目标已存在，先检查差异并把旧目录备份到 Skills 发现目录之外。之后只更新 `.agents` 的真实目录；不要把安装器指向符号链接路径，安装器会为避免覆盖权威源而拒绝 reparse path。

### 2. 项目内 vendoring

把完整 bundle 放入项目，例如：

```text
<plugin-project>/skills/asa-api-plugin-dev/
```

再由项目支持的入口文件指向：

```text
skills/asa-api-plugin-dev/SKILL.md
```

不要只复制 `AGENTS.md` 或 `CLAUDE.md`。单独复制会让 `SKILL.md` 和 `references/` 的相对路径失效。

### 3. 显式引用

当 Agent 不支持自动发现时，在任务中直接写：

```text
读取并遵守 <absolute-or-repo-path>/skills/asa-api-plugin-dev/SKILL.md，
并以该目录为根按需读取 references。
```

这种方式不依赖客户端品牌，只要求 Agent 能读取文件并执行相应开发工具。

## 客户端适配边界

- Codex、Claude Code、Gemini CLI、Cursor、Copilot 等客户端可以拥有不同的自动发现目录和入口文件。
- 自动发现路径、UI 元数据、Slash Command、允许工具字段都属于客户端适配层，不应进入核心 ASA 规则。
- 客户端不支持某个示例工具时，使用等价能力。例如没有 `rg` 时可用 `git grep`、`Select-String` 或内置代码搜索。
- Windows、MSVC/MSBuild、PowerShell 和 AsaApi SDK 属于 ASA 插件构建环境约束，不是 Agent 厂商耦合，应保留在通用 Skill 中。

## 维护与同步

1. 先修改受版本控制的 `skills/asa-api-plugin-dev` 权威源。
2. 同步需要面向人阅读的 `docs/`。
3. 校验 Skill 结构、相对引用和格式。
4. 再同步客户端部署副本。
5. 部署副本存在独立修改时使用三方合并；不能用 `-Replace` 悄悄覆盖冲突。

只访问到部署副本时，应先定位权威仓库。找不到或无写权限时，生成候选补丁或待同步说明，不要声称公共 Skill 已更新。

## 通用任务示例

```text
使用 asa-api-plugin-dev Skill 审查当前 ASA 插件的 Hook、配置和发布包；
区分源码检查、本地构建、打包结果与真实上服验证。
```

```text
读取 <guide>/skills/asa-api-plugin-dev/SKILL.md，
按发布门禁重新构建并验证这个插件的 Release 包。
```
