# API 来源与结论分级

本项目的内容分三类：

1. **官方/API 可验证事实**：来自 ASA API Wiki、ArkServerApi GitHub、本地 AsaApi SDK 头文件。
2. **社区常见结构**：来自常见插件发布包，例如 `PluginName.dll`、`PluginInfo.json`、`config.json`、`config说明.json`。
3. **工程判断**：来自插件维护、排错和实测，需要写清楚适用条件，不应伪装成 wiki 标准。

写文档或让 Agent 执行任务时，必须先判断当前内容属于哪一类。

## Wiki 能确认什么

ASA API Wiki 是 Doxygen 风格 API 索引，适合确认接口和源码结构。

可从 wiki 确认的通用事实包括：

- ASA API 是面向 Windows 服务器的 ArkServerAPI 插件接口。
- `Commands` 提供聊天命令、控制台命令、RCON 命令、tick 回调、timer 回调、聊天消息回调等能力。
- `AddOnTickCallback` 是每帧调用；`AddOnTimerCallback` 是每秒调用。
- `Hooks::SetHookInternal` 会通过 offset 查找目标函数，目标不存在时返回失败并记录错误。
- `MessagingManager` 用于发送 server messages、notifications 和 chat messages。
- `PluginManager` 负责查找、加载、卸载和重载插件。

这些属于 API 事实，可以写进指南。

## 官方资源页能确认什么

ASA Server API 官方资源页适合确认安装和部署事实：

- ASA Server API 用于把插件加载进 ARK: Survival Ascended 服务器。
- API 解压到 `ARK\ShooterGame\Binaries\Win64`。
- 插件解压到 `ARK\ShooterGame\Binaries\Win64\ArkApi\Plugins`。
- 插件目录名和 DLL 名需要匹配，否则可能导致插件无法读取目录或启动失败。
- ArkApi 日志和 crash 日志有固定位置说明。

这些属于部署事实，可以写进指南。

## Wiki 通常不会告诉你什么

Wiki 通常不会直接告诉你：

- 某个业务插件应该选哪个 Hook。
- 某个字段写入是否在游戏内真的生效。
- 哪个函数在多插件共存时一定安全。
- 某个服务器无响应的唯一根因。
- 某个作者的配置说明文件名是否是行业标准。

这些只能写成“工程判断”或“需要实测”。

## 写文档时的标注方式

推荐这样写：

```text
API 事实：Commands 提供 AddChatCommand / AddConsoleCommand / AddRconCommand。
工程判断：命令回调内逻辑应尽量短，复杂逻辑可拆到服务层或延迟任务。
需要实测：某个游戏对象字段写入后是否在 UI 和战斗中都生效。
```

不要这样写：

```text
所有插件都必须延迟发送命令回执。
某个具体函数一定会崩。
某次插件冲突就是通用规律。
```

## Agent 使用要求

Agent 写代码或文档时：

- API 名称、函数签名、类成员必须从本地 SDK 或 wiki 确认。
- 不能把某个私有插件排错结论写成通用 API 规则。
- 对无法从 wiki 或 SDK 证明的内容，用“建议、风险、需要验证”表达。
- 如果要求“按官方/wiki 来”，优先输出 API 事实，不扩展过多工程判断。

## 常用链接

- ASA API Wiki: https://arkserverapi.wiki/asa/index.html
- ASA API Wiki main page lists classes, files, functions and source files rather than step-by-step plugin design guidance.
- Commands source: https://arkserverapi.wiki/asa/_commands_8cpp_source.html
- Hooks source: https://arkserverapi.wiki/asa/_hooks_8cpp_source.html
- MessagingManager: https://arkserverapi.wiki/asa/_messaging_manager_8h.html
- PluginManager source: https://arkserverapi.wiki/asa/_plugin_manager_8cpp_source.html
- Official ASA Server API resource: https://ark-server-api.com/resources/asa-server-api.31/
