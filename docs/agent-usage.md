# Agent 使用

本仓库可以给 Codex、Claude Code 等 Agent 使用。它不是一个可安装到 ASA 服务器的插件，也不是一个自动安装型 skill，而是 Agent 的项目级指导仓库。

## 推荐入口

- Codex / OpenAI Codex：读取 `AGENTS.md`
- Claude Code：读取 `CLAUDE.md`
- 人工阅读：从 `README.md` 和 `docs/README.md` 开始

## 安装到实际插件项目

如果要让 Agent 在某个 ASA 插件项目里自动遵守这套规则，最直接的方式是把入口文件复制到那个插件项目根目录：

```powershell
Copy-Item .\AGENTS.md <plugin-project>\AGENTS.md
Copy-Item .\CLAUDE.md <plugin-project>\CLAUDE.md
```

然后在任务里告诉 Agent：

```text
按项目根目录的 AGENTS.md / CLAUDE.md 开发这个 ASA API 插件。
```

如果不想复制文件，也可以把本仓库作为旁边的参考仓库，在任务里明确引用：

```text
参考 asa-api-plugin-dev-guide 的 AGENTS.md 和 docs/release-checklist.md，检查当前插件。
```

建议：

- 长期维护的插件项目：复制 `AGENTS.md` / `CLAUDE.md` 到插件根目录。
- 临时排错或一次性审查：直接引用本仓库。
- 团队共用规范：把本仓库作为私有规范仓库，插件项目只保留简短引用。

## 安装 Codex skill

本仓库已经包含 Codex skill：

```text
skills/asa-api-plugin-dev
```

安装：

```powershell
.\scripts\install-skill.ps1 -Force
```

安装后重启 Codex 或新开一个会话，让 skill 列表刷新。

## 和指南文档的关系

本仓库适合放完整文档：

- 原则
- API 查询流程
- 稳定性建议
- 配置说明写法
- 排错流程
- 发布检查清单
- 模板结构

Codex skill 适合放短规则：

- 什么时候触发
- 先读哪些文件
- 不要做什么
- 完成时必须验证什么

推荐组合：

```text
asa-api-plugin-dev-guide
├── AGENTS.md
├── CLAUDE.md
├── docs/
└── templates/

skills/
└── asa-api-plugin-dev/
    ├── SKILL.md
    └── references/
```

Agent 执行实际插件任务时，应以当前插件项目为工作区，把本仓库作为规范参考。

## 给 Agent 的任务写法

推荐：

```text
参考 asa-api-plugin-dev-guide 的 AGENTS.md，帮我检查这个 ASA API 插件的配置、Hook 和打包流程。
```

或者：

```text
按 asa-api-plugin-dev-guide 的发布检查清单，准备这个插件的 Release 包。
```

不推荐：

```text
安装这个项目到服务器。
```

因为它不是服务器插件。

## 写入本仓库的原则

Agent 更新本仓库时，只写通用规则，不写具体服务器事故。

可以写：

- “Hook 签名应标明确认来源，例如本地 SDK、项目现有代码或 wiki。”
- “说明配置应保留真实结构并解释字段。”
- “服务器不在本机时，只报告本地验证结果，并列出服务器侧待验证项。”

不要写：

- 某个私有插件的测试过程。
- 某个服务器的路径、账号、IP。
- 某次具体冲突直接等同于通用规律。
