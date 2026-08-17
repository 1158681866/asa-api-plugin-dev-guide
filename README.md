# ASA API 插件开发指南

面向 Ark Survival Ascended 的 AsaApi / ArkServerApi C++ 插件开发指导项目。

这个仓库不是服务器插件 DLL。它同时提供开发手册、项目模板、发布检查清单和一个遵循 [Agent Skills 开放格式](https://agentskills.io/specification) 的可移植 Skill，目标是让 ASA API 插件从“能编译”走向“可验证、可排错、可发布、可维护”。

## 这个项目能做什么

- 指导 ASA AsaApi C++ 插件开发。
- 规范 ArkServerApi / AsaApi Hook 查询、签名确认和风险评估。
- 提供聊天命令、RCON 命令、配置热重载、游戏内消息的设计建议。
- 提供崩服、服务器无响应、无 crash 日志、功能不生效时的排错流程。
- 提供配置说明、测试、编译、打包、发布和回滚检查清单。
- 提供可复制的新插件目录结构模板。
- 提供跨 Agent 使用的 `asa-api-plugin-dev` Skill；平台专用文件仅作为自动发现适配器。

## 适用范围

- ASA AsaApi C++ 插件开发
- ArkServerApi / AsaApi Hook 接入
- 聊天命令、控制台命令、RCON 命令
- JSON 配置、配置说明、热重载
- 游戏内聊天消息、服务器消息、屏幕通知
- 崩服、卡服、断联、无 crash 日志排查
- 插件打包、版本发布、上服测试
- 多个 ASA API 插件共存时的兼容检查

## 不适用范围

- UE Mod 蓝图开发
- 非 AsaApi 的独立服务端程序
- 未经验证的内存偏移硬改
- 私服业务规则、经济数值、奖励表、聊天话术沉淀
- 未说明来源和验证方式的确定性结论

## 快速开始

```powershell
git clone https://github.com/1158681866/asa-api-plugin-dev-guide.git
cd asa-api-plugin-dev-guide
```

人工阅读从 `docs/README.md` 开始。Agent 使用时，权威入口始终是：

```text
skills/asa-api-plugin-dev/SKILL.md
```

完整 bundle：

```text
skills/asa-api-plugin-dev/
├── SKILL.md
├── references/
└── agents/openai.yaml   # 可选 OpenAI UI 适配元数据
```

`SKILL.md` 与 `references/` 承载通用规则。根目录 `AGENTS.md`、`CLAUDE.md` 是仓库级薄入口；`agents/openai.yaml` 是可选 OpenAI UI/调用策略元数据。它们都不维护另一套 ASA 开发规则。

## 安装到支持 Agent Skills 的客户端

把整个 `skills/asa-api-plugin-dev` 目录复制到所用 Agent 当前文档声明的 Skills 根目录。Windows 下可用通用安装脚本：

```powershell
.\scripts\install-skill.ps1 -SkillsRoot '<agent-skills-root>'
```

或者直接指定最终目录：

```powershell
.\scripts\install-skill.ps1 -Destination '<agent-skills-root>\asa-api-plugin-dev'
```

目标已存在时默认拒绝覆盖。确需替换时使用 `-Replace`，脚本会先在 Skills 发现目录之外创建时间戳备份；可用 `-BackupRoot` 显式指定备份根目录。各客户端路径只是适配信息，不属于 Skill 标准。当前常见做法：

- Codex、Gemini CLI、Cursor、GitHub Copilot 等客户端支持用户级 `~/.agents/skills` 或项目级 `.agents/skills`。
- Claude Code 使用个人 `~/.claude/skills` 或项目 `.claude/skills`，可以链接到同一份 `.agents/skills/asa-api-plugin-dev`，避免维护重复副本。
- 旧版或定制客户端可能仍使用自己的历史目录；以其当前官方文档为准，不把历史路径写进核心 Skill。

不支持自动发现的 Agent 也可以显式读取：

```text
读取并遵循 <guide>/skills/asa-api-plugin-dev/SKILL.md，
所有 references 路径以该 Skill 目录为基准，只加载当前任务需要的文件。
```

不要只复制 `AGENTS.md` 或 `CLAUDE.md`；脱离完整 bundle 后相对引用会失效。详细集成方式见 [`docs/agent-usage.md`](docs/agent-usage.md) 和 [`docs/usage.md`](docs/usage.md)。

仓库内置一个不依赖特定 Agent 客户端的基础格式检查：

```powershell
.\scripts\validate-skill.ps1
```

发布或对外共享前，还可以使用 Agent Skills 官方参考校验器。中文 Windows 终端先强制 Python 使用 UTF-8：

```powershell
$env:PYTHONUTF8='1'
uvx --from skills-ref agentskills validate ./skills/asa-api-plugin-dev
```

如果已经从源码安装参考工具，也可以使用它提供的等价 `skills-ref validate` 入口。
## 新插件项目结构

可以复制模板目录作为新插件起点：

```powershell
Copy-Item -Recurse .\templates\plugin-skeleton ..\my-plugin
```

推荐结构：

```text
plugin-name/
├── src/
│   ├── core/
│   │   ├── config.*
│   │   └── service.*
│   ├── plugin/
│   │   └── plugin_main.cpp
│   └── third_party/
├── tests/
│   └── test_main.cpp
├── build/
│   └── package/
├── PluginInfo.json
├── config.json
├── config说明.json
├── package.ps1
└── README.md        # 源码仓库的开发者/维护文档
```

核心思路：

- `core` 放纯逻辑、配置解析、状态管理、模板替换，尽量能用普通 exe 测试。
- `plugin` 放 AsaApi Hook、命令注册、游戏对象读写。
- `tests` 覆盖不依赖服务器的逻辑。
- `build/package/<Plugin>` 放本地测试目录，可以保留开发文档副本和本地配置；它不是最终对外发放级产物。

## 本地测试目录与对外 ZIP

`build/package/<Plugin>/` 用于本地检查或测试部署，可以保留 `README.md`、`CHANGELOG.md` 副本和本地配置。例如：

```text
build/package/PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
├── README.md          # 可选的本地测试副本
└── CHANGELOG.md       # 可选的本地测试副本
```

只有最终对外 ZIP 属于发放级产物。ZIP 解压后应是服务器管理员能直接复制到 `ArkApi/Plugins` 的结构：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
└── <运行必需的额外文件>  # 仅在插件确实依赖时加入
```

常见约定：

- `PluginInfo.json` 放在插件根目录。
- `config.json` 是插件运行时读取的严格 JSON，不写 `//` 注释。
- `config说明.json` 是必需的中文配置说明文件，只保留与公开字段相邻的必要说明；默认增加简短“插件信息”对象，用 `插件加载命令`、`插件卸载命令`、`配置重载命令` 三个明确字段列出 `plugins.load <FullName>`、`plugins.unload <FullName>` 和配置重载。配置重载只读取配置，更换 DLL 要卸载、替换、加载或重启。默认在插件信息和配置项说明前添加简短分隔标题，用户明确说不要时才省略；仍不写联系方式、完整命令列表或长注意事项；安装和上服验证放在源码仓库的 README、项目文档或 wiki。
- 最终对外 ZIP 默认只包含 DLL、`PluginInfo.json`、`config.json`、`config说明.json`。`.dll.arkapi`、附属运行库、签名或数据文件等只有在插件运行确实需要时才加入。
- `README.md`、`CHANGELOG.md` 等属于开发者/维护文档，可以留在源码树和本地测试目录，但不进入最终对外 ZIP，也不能算作“运行必需的额外文件”。
- 打包时优先使用临时 ZIP staging 或显式 ZIP 白名单；也可以先生成 ZIP，再把文档副本放回本地测试目录。不得为了精简 ZIP 删除测试目录或源码里的文档，也不得覆盖测试目录里的本地配置。
- 如果说明文件里有 `//` 注释，即使命名为 `.json`，也不是严格 JSON，插件运行时不应读取它。
- 每次打包后检查 DLL 时间，避免误拷旧包。

## 开发原则

简要原则：

- 先读现有代码，再决定改法。
- 先确认 API / Hook 签名，再写代码。
- API 名称、Hook 签名、字段名优先以官方文档 / ASA API Wiki 为准；Wiki 足够时不查 SDK。只有 Wiki 缺资料、疑似过期或编译/签名对不上时，再用本地 AsaApi SDK 补充确认。
- 区分 API 事实、社区常见结构和工程判断。
- 不确定的 Hook 签名、字段名、调用链标记为“待确认”，不要写成确定结论。
- 大范围扫描、高频 Hook、脚本派发、状态同步、setter 等做法不是一概不能用；采用前要说明业务必要性、触发频率、范围限制、日志和回滚方式。
- 插件与数据库 / Web / 机器人联动时，先参考 ArkShop / ICE 等成熟插件和当前项目已有做法；不要默认引入 Web API 中转，插件直连 MySQL、读取本地配置、调用现有插件命令都是 ASA 插件生态里的常见落地方式。
- 行为改动要同步更新代码、默认配置、说明文档、测试、包内文件。
- 服务器不在本机时，本地只能证明“编译/测试/打包通过”，不能声称“上服验证通过”。

## 配置与命令建议

配置设计要区分两类内容：

- 服务器管理员经常调整的玩法、文案、倍率、概率、奖励、列表类内容，优先配置化。
- 内部技术参数、临时排错参数、错误配置后风险较高的参数，不默认暴露；需要暴露时写清适用场景和安全范围。
- 涉及 Permissions/VIP 多档价格、冷却、额度、奖励或保护时，先读取目标服务器真实组名和等级来源，再使用包含 `Default` 普通档的统一结构化组规则数组。正式配置默认只保留 `Default`，未列出的 VIP 使用通用档，只有值确实不同才追加；不预填大量相同规则。玩家命中多组时取最高有效档，已有权威等级或明确数组顺序时不重复增加 `Name`、`Default: true`、`Priority`。仅在确实要禁止部分组使用时增加 `AllowedGroups`；普通用户也允许使用时不重复配置白名单。

命令建议：

```text
/plugin
/plugin <mode>
/plugin status
/plugin cancel
/plugin reload
Plugin.Reload
```

RCON / 控制台重载可以减少重启服务器次数。玩家可见回执要和配置、README、测试流程保持一致。

## 通知与聊天接口

常见接口区别：

- `SendChatMessage(player, sender_name, msg)`：普通聊天行，有发送者名，通常没有单独颜色参数。
- `SendServerMessage(player, color, msg)`：服务器消息样式，有颜色。
- `SendNotification(player, color, scale, time, icon, msg)`：屏幕通知，不进入普通聊天历史。
- `ClientServerChatDirectMessage(&message, color, bold, &sender)`：直发聊天行，有发送者名和颜色，但不同服务器/插件组合下样式可能接近服务器直发消息。

所有接口优先按官方文档 / ASA API Wiki 核对签名；Wiki 足够时不再为了“保险”翻 SDK。选择接口时以目标游戏内样式、稳定性和可验证性为准，不把某一次项目表现写成所有插件的固定结论。

## 排错流程

遇到崩服、断联、无响应、功能不生效时，优先按这个顺序走：

1. 确认服务器 ASA 版本、AsaApi 版本、插件版本和 DLL 时间。
2. 收集 `ArkApi_*.log`、`ShooterGame.log`、crash callstack 或最后一屏 CMD 输出。
3. 找到最后一条插件阶段日志。
4. 最小化复现：关掉非必要功能、缩小 Hook、禁用高风险路径。
5. 对象访问前检查对象来源、生命周期和类型。
6. 如果没有 crash 但服务器无响应，重点排查高频 Hook、阻塞 IO、网络请求、死循环、timer 残留。
7. 修复后跑 Release 编译、core tests、打包，并明确服务器侧还要验证什么。

中文日志或 `PluginInfo.json` 描述乱码时，先按日志前缀区分插件自有日志和 AsaApi core 加载日志，再查源码编码、控制台代码页和 `FString`/UTF-8 转换链路。

## 发布检查

发布前至少确认：

- Release 编译通过。
- core tests 通过。
- 本地 `build/package/<Plugin>` 测试目录已刷新，且未因精简 ZIP 丢失开发文档副本或本地配置。
- DLL 时间是新的。
- `PluginInfo.json` 存在。
- `config.json` 能解析。
- `config说明.json` 反映当前公开配置；源码仓库里的 README / 项目文档反映当前真实逻辑。
- 最终对外 ZIP 不包含 `README.md`、`CHANGELOG.md` 等仅供开发者阅读的文档；额外文件均有明确运行依赖依据。
- Debug 日志受配置控制或已清理。
- 注册的命令、Hook、timer 在卸载/重载时能清理。
- 保留上一版可回滚 DLL 和配置。

完整清单见 [docs/release-checklist.md](docs/release-checklist.md)。

## 文档目录

推荐阅读顺序：

1. [使用方式](docs/usage.md)
2. [Agent Skill 集成](docs/agent-usage.md)
3. [开发原则](docs/principles.md)
4. [开发流程](docs/development-workflow.md)
5. [环境与 SDK](docs/environment.md)
6. [项目结构](docs/project-structure.md)
7. [API 来源与结论分级](docs/official-api-sources.md)
8. [API 与 Hook 查询](docs/api-lookup.md)
9. [稳定性建议](docs/stability.md)
10. [数据库与外部系统](docs/database-and-integrations.md)
11. [配置与命令](docs/config-and-commands.md)
12. [通知与聊天](docs/messaging.md)
13. [测试、编译与打包](docs/build-test-package.md)
14. [排错手册](docs/debugging.md)
15. [指南迭代](docs/skill-evolution.md)
16. [发布检查清单](docs/release-checklist.md)

## 贡献方式

推荐协作逻辑：

- `main` 是稳定版。
- 不维护长期 `dev` 分支。
- 每次修改从 `main` 拉临时分支。
- 改完发 Pull Request。
- 审核通过后合并回 `main`。
- 合并后删除临时分支。

分支命名建议：

```text
docs/xxx      文档修改
skill/xxx     skill 修改
fix/xxx       修错
chore/xxx     仓库维护
```

贡献前检查：

- 没有私有路径、服务器地址、账号、token、未脱敏日志。
- 没有把单次事故写成通用规则。
- 没有未经官方文档 / ASA API Wiki / 必要时本地 SDK 或源码确认的 Hook 签名或字段名。
- 如果改了 skill，也同步考虑 docs 是否需要更新。
- 如果改了 docs，也同步考虑 `skills/asa-api-plugin-dev/references/` 是否需要更新。

更多规则见 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [docs/maintenance.md](docs/maintenance.md)。

## 指南迭代规则

这个仓库会吸收实际开发经验，但只吸收“通用化后的经验”。

可以写入：

- 多个 ASA API 插件都能复用的流程、检查项、验证方法。
- 多类插件都会遇到的风险判断，例如 Hook 频率、对象生命周期、状态同步、配置回滚。
- 能通过官方文档、ASA API Wiki、ArkServerApi GitHub，或必要时本地 SDK / 项目源码确认的 API 事实。
- 经过多场景验证，并写清适用条件和限制的工程模式。

不写入：

- 单个服务器、单个插件业务、单个作者习惯。
- 私有路径、私有日志、聊天话术、经济数值、奖励配置。
- 某次事故的原始结论。
- 未确认来源的 Hook 签名、字段名、蓝图路径或性能结论。

具体规则见 [docs/skill-evolution.md](docs/skill-evolution.md)。

## 官方/常用资料

- ASA API Wiki: https://arkserverapi.wiki/asa/index.html
- ArkServerApi/AsaApi GitHub: https://github.com/ArkServerApi/AsaApi

## 许可证

见 [LICENSE](LICENSE)。
