# 使用方式

这个仓库是 ASA API 插件开发指导项目，不是一个可以放进服务器的插件 DLL。

它默认有三种用法：

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

## 配合 Codex 使用

这个仓库本身不是 Codex skill。它更像一份可维护的知识库和项目模板。

如果要让 Codex 自动按这些规则工作，有两种方式：

- 在请求里明确让 Codex 参考本仓库。
- 另外维护一个真正的 Codex skill，把核心规则写进 `SKILL.md`。

推荐做法是两层分工：

- 本仓库：放详细文档、模板、检查清单、维护记录。
- Codex skill：放短规则和工作流，让 Codex 每次开发插件时自动执行。

这样不会把 skill 写得太臃肿，也不会让详细文档散落在聊天记录里。

## 更新方式

这类仓库建议长期维护：

```powershell
git pull
```

新增经验时优先更新已有专题文档，不要只追加零散笔记。

如果某条经验来自某个具体插件事故，写入前要先泛化，避免把只适用于某个服务器、某个插件、某次冲突的结论当成通用标准。
