# 使用方式

这个仓库是 ASA API 插件开发指导项目，不是可以放进服务器的插件 DLL。

## 作为文档参考

克隆仓库后，从 `README.md` 和 `docs/README.md` 开始阅读：

```powershell
git clone https://github.com/1158681866/asa-api-plugin-dev-guide.git
cd asa-api-plugin-dev-guide
```

## 作为通用 Agent Skill

权威 Skill bundle 位于：

```text
skills/asa-api-plugin-dev/
├── SKILL.md
├── references/
└── agents/openai.yaml   # 可选的 OpenAI 客户端 UI 适配元数据
```

`SKILL.md` 采用 [Agent Skills 开放格式](https://agentskills.io/specification)。任何能够读取该格式的 Agent 都可以安装完整目录；不支持自动发现的 Agent 也可以显式读取 `SKILL.md`，再按需读取 `references/`。

通用安装方式是把整个 `skills/asa-api-plugin-dev` 目录复制到所用客户端的 Skills 根目录。目录位置由客户端决定，不要把某个厂商路径当成 Skill 标准的一部分。

Windows 下可以显式指定目标根目录：

```powershell
.\scripts\install-skill.ps1 -SkillsRoot '<agent-skills-root>'
```

也可以直接指定最终目录：

```powershell
.\scripts\install-skill.ps1 -Destination '<agent-skills-root>\asa-api-plugin-dev'
```

目标已存在时脚本默认拒绝覆盖。确认需要替换时使用 `-Replace`；脚本会先在 Skills 发现目录之外创建时间戳备份，也可用 `-BackupRoot` 指定位置。更新前仍应检查部署副本是否有本地修改。

客户端路径示例只属于适配信息：

- Codex、Gemini CLI、Cursor、GitHub Copilot 等客户端支持用户级 `~/.agents/skills` 或项目级 `.agents/skills`。
- Claude Code 个人 Skill 使用 `~/.claude/skills`，项目 Skill 使用 `.claude/skills`；优先通过目录符号链接指向同一份 `.agents/skills/asa-api-plugin-dev`。Windows junction 只作为客户端实测可发现后的兼容后备。
- 旧版或定制 Agent 使用其当前文档声明的 Skills 根目录；若不支持安装，则在任务中显式提供 `SKILL.md` 路径。

统一部署时，先把真实目录安装到 `~/.agents/skills`，再为仅扫描其他目录的客户端创建目录符号链接。后续只更新真实目录，不要让安装器穿过符号链接或 junction；脚本会主动拒绝这种路径。

安装后是否需要重启、刷新会话或重新索引，也以客户端当前规则为准。

基础格式验证：

```powershell
.\scripts\validate-skill.ps1
```

若已安装 Agent Skills 官方参考工具，也可运行：

```powershell
$env:PYTHONUTF8='1'
uvx --from skills-ref agentskills validate ./skills/asa-api-plugin-dev
```

从源码安装参考工具时，也可以使用它提供的等价 `skills-ref validate` 入口。

## 项目级 Agent 入口

仓库根目录的 `AGENTS.md`、`CLAUDE.md` 是项目级薄入口，负责让对应客户端读取 `skills/asa-api-plugin-dev/SKILL.md`。`skills/asa-api-plugin-dev/agents/openai.yaml` 是可选 OpenAI UI/调用策略元数据，随 Skill bundle 使用；其他客户端可以忽略。三者都不维护第二份 ASA 开发规则。

不要只复制根目录入口文件，因为其中的相对路径会失效。要么安装完整 Skill bundle，要么把完整 bundle 一起 vendoring 到目标项目，再让入口文件指向它。

任何 Agent 都可以使用下面的显式任务写法：

```text
读取并遵循 <guide-repo>/skills/asa-api-plugin-dev/SKILL.md。
所有 references 路径以该 Skill 目录为基准，只加载当前任务需要的文件。
```

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
- `README.md`

模板只提供结构思路，不包含可直接编译的 C++ 代码。

## 更新方式

权威源更新：

```powershell
git pull
```

随后将变更安全同步到各客户端部署副本。部署副本有本地改动时先做三方合并；不要用整目录删除再复制的方式掩盖冲突。
