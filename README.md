# ASA API 插件开发指南

面向 Ark Survival Ascended 的 AsaApi / ArkServerApi C++ 插件开发指导项目。

这个仓库不是某一个服务器插件，也不是可以直接放进 `ArkApi/Plugins` 的 DLL。它是一套给开发者和 AI Agent 使用的开发手册、Codex skill、项目模板和发布检查清单，目标是让 ASA API 插件从“能编译”走向“可验证、可排错、可发布、可维护”。

## 这个项目能做什么

- 指导 ASA AsaApi C++ 插件开发。
- 规范 ArkServerApi / AsaApi Hook 查询、签名确认和风险评估。
- 提供聊天命令、RCON 命令、配置热重载、游戏内消息的设计建议。
- 提供崩服、服务器无响应、无 crash 日志、功能不生效时的排错流程。
- 提供配置说明、测试、编译、打包、发布和回滚检查清单。
- 提供可复制的新插件目录结构模板。
- 提供 Codex skill，方便 Codex 在处理 ASA API 插件任务时自动套用这套规则。

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

克隆仓库：

```powershell
git clone https://github.com/1158681866/asa-api-plugin-dev-guide.git
cd asa-api-plugin-dev-guide
```

推荐先看：

```text
README.md
docs/README.md
AGENTS.md
docs/release-checklist.md
```

如果你是人工开发者，先读 `docs/README.md` 进入专题文档。如果你是让 Codex、Claude Code 等 Agent 工作，先看 `AGENTS.md`、`CLAUDE.md` 和 `docs/agent-usage.md`。

## 安装为 Codex Skill

仓库内置 Codex skill：

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

安装后重启 Codex 或新开会话，让 skill 列表刷新。

这个 skill 会在任务涉及 ASA API 插件、ArkServerApi/AsaApi Hook、配置文件、聊天命令、游戏内通知、崩服日志、打包发布时触发。skill 的作用是给 Agent 一个短流程入口；完整解释仍放在 `docs/` 中。

## 配合 Agent 使用

本仓库提供两个项目级入口：

```text
AGENTS.md
CLAUDE.md
```

推荐用法：

- Codex：读取 `AGENTS.md`。
- Claude Code：读取 `CLAUDE.md`。
- 长期维护的插件项目：把 `AGENTS.md` / `CLAUDE.md` 复制到实际插件项目根目录。
- 临时排错或审查：在任务里明确要求参考本仓库。

示例任务：

```text
参考 asa-api-plugin-dev-guide 的 AGENTS.md，检查这个 ASA API 插件的 Hook、配置和打包流程。
```

```text
按 asa-api-plugin-dev-guide 的发布检查清单，准备这个插件的 Release 包。
```

不要把本仓库“安装到 ASA 服务器”。服务器需要的是实际插件包，本仓库只是开发指导项目。

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
└── README.md        # 可选
```

核心思路：

- `core` 放纯逻辑、配置解析、状态管理、模板替换，尽量能用普通 exe 测试。
- `plugin` 放 AsaApi Hook、命令注册、游戏对象读写。
- `tests` 覆盖不依赖服务器的逻辑。
- `build/package` 放服务器可直接复制的发布包。

## 发布包结构

发布包应该是服务器管理员能直接复制到 `ArkApi/Plugins` 的结构：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
├── README.md        # 可选
└── CHANGELOG.md
```

常见约定：

- `PluginInfo.json` 放在插件根目录。
- `config.json` 是插件运行时读取的严格 JSON，不写 `//` 注释。
- `config说明.json` 是必需的中文配置说明文件，只给人看，可以解释字段、倍率、概率、重载命令和注意事项。
- `README.md` 可选，适合写项目总览、安装和排错入口。
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
- 包目录刷新。
- DLL 时间是新的。
- `PluginInfo.json` 存在。
- `config.json` 能解析。
- 配置说明和 README 反映当前真实逻辑。
- Debug 日志受配置控制或已清理。
- 注册的命令、Hook、timer 在卸载/重载时能清理。
- 保留上一版可回滚 DLL 和配置。

完整清单见 [docs/release-checklist.md](docs/release-checklist.md)。

## 文档目录

推荐阅读顺序：

1. [使用方式](docs/usage.md)
2. [Agent 使用](docs/agent-usage.md)
3. [开发原则](docs/principles.md)
4. [开发流程](docs/development-workflow.md)
5. [环境与 SDK](docs/environment.md)
6. [项目结构](docs/project-structure.md)
7. [API 来源与结论分级](docs/official-api-sources.md)
8. [API 与 Hook 查询](docs/api-lookup.md)
9. [稳定性建议](docs/stability.md)
10. [配置与命令](docs/config-and-commands.md)
11. [通知与聊天](docs/messaging.md)
12. [测试、编译与打包](docs/build-test-package.md)
13. [排错手册](docs/debugging.md)
14. [指南迭代](docs/skill-evolution.md)
15. [发布检查清单](docs/release-checklist.md)

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
