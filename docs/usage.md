# 使用方式

这个仓库是 ASA API 插件开发指导项目，不是一个可以放进服务器的插件 DLL。

它默认有四种用法：

## 作为文档参考

克隆仓库后直接阅读：

```powershell
git clone https://github.com/<owner>/asa-api-plugin-dev-guide.git
cd asa-api-plugin-dev-guide
```

推荐从 `README.md` 和 `docs/README.md` 开始看。

## 作为新插件起点

复制模板目录：

```powershell
Copy-Item -Recurse .\templates\plugin-skeleton ..\my-plugin
```

然后按实际插件名补齐：

- `PluginInfo.json`
- `config.json`
- `config说明.json` 或 `config-commented.json`
- `src/core`
- `src/plugin`
- `tests`
- `package.ps1`
- `README.md`

模板目录只提供结构思路，不包含可直接编译的 C++ 代码。

## 安装为 Codex Skill

仓库内置了 Codex skill：

```text
skills/asa-api-plugin-dev
```

安装到当前 Windows 用户的 Codex skills 目录：

```powershell
.\scripts\install-skill.ps1 -Force
```

等价手动安装：

```powershell
Copy-Item -Recurse .\skills\asa-api-plugin-dev "$env:USERPROFILE\.codex\skills\asa-api-plugin-dev" -Force
```

安装后重启 Codex 或新开一个会话，让 skill 列表刷新。

触发场景包括：

- ASA API 插件开发
- ArkServerApi / AsaApi Hook
- 配置文件和命令
- 游戏内通知和聊天
- 崩服、无响应、无 crash 日志排错
- 编译、测试、打包、发布

## 配合其他 Agent 使用

Codex skill 适合 Codex 自动触发；其他 Agent 通常读取项目入口文件。

Codex、Claude Code 等 Agent 可以直接读取：

```text
AGENTS.md
CLAUDE.md
```

要让某个实际插件项目自动套用规则，可以把这两个文件复制到该插件项目根目录。Codex 通常读取 `AGENTS.md`，Claude Code 通常读取 `CLAUDE.md`。

推荐做法是三层分工：

- 本仓库：放详细文档、模板、检查清单、维护记录。
- Codex skill：放短规则和工作流，让 Codex 每次开发插件时自动执行。
- `AGENTS.md` / `CLAUDE.md`：给项目级 Agent 读取。

这样不会把 skill 写得太臃肿，也不会让详细文档散落在聊天记录里。

## 更新方式

这类仓库建议长期维护：

```powershell
git pull
```

新增经验时优先更新已有专题文档，不要只追加零散笔记。

如果某条经验来自某个具体插件事故，写入前要先泛化，避免把只适用于某个服务器、某个插件、某次冲突的结论当成通用标准。
