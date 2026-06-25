# 使用方式

这个仓库是 ASA API 插件开发指导项目，不是一个可以放进服务器的插件 DLL。

主要用法：

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
- `config说明.json`
- `src/core`
- `src/plugin`
- `tests`
- `package.ps1`
- `README.md` 可选

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

## 配合 Agent 使用

Codex skill 适合 Codex 自动触发；其他 Agent 通常读取项目入口文件。

Codex、Claude Code 等 Agent 可以直接读取：

```text
AGENTS.md
CLAUDE.md
```

要让某个实际插件项目自动套用规则，可以把这两个文件复制到该插件项目根目录。Codex 通常读取 `AGENTS.md`，Claude Code 通常读取 `CLAUDE.md`。

推荐分工：

- 本仓库：完整开发手册、模板和检查清单。
- Codex skill：短规则和任务路由，便于 Codex 自动触发。
- `AGENTS.md` / `CLAUDE.md`：项目级 Agent 指令，可复制到实际插件项目。

详细设计、接口依据和验证结论应沉淀到专题文档；skill 和 Agent 入口只保留执行所需的短规则。

## 更新方式

更新仓库：

```powershell
git pull
```

提交并推送当前仓库改动：

```text
双击 push.cmd
```

需要自定义提交信息时：

```powershell
.\scripts\push.ps1 -Message "docs: update guide"
```

默认会先把仓库内置 skill 安装到当前用户的 Codex skills 目录，再提交并推送。只想推送仓库、不安装本地 skill 时：

```powershell
.\scripts\push.ps1 -Message "docs: update guide" -NoInstall
```

新增结论时优先更新已有专题文档。无法从 SDK、wiki 或可复现实测确认的内容，应标记为建议或待验证。
