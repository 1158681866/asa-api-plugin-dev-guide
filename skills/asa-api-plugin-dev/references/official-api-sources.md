# API 来源与结论分级

把内容分成三类：

- API 事实：优先来自官方文档 / ASA API Wiki / ArkServerApi GitHub；官方资料足够时不查 SDK。本地 AsaApi SDK 只用于解决官方未覆盖、写得不清楚、疑似过期，或已经出现签名/编译不一致的问题。
- 社区常见结构：来自常见插件发布包结构。
- 工程判断：来自排错、维护和实测，需要写清楚适用条件，不应伪装成 wiki 标准。

Wiki 能确认接口、类、函数、源码结构；但通常不会告诉你某个业务插件该选哪个 Hook、某个字段写入是否在游戏内生效、某个多插件冲突的唯一根因。

Agent 写代码或文档时：

- API 名称、函数签名、类成员优先从官方文档 / wiki 确认；wiki 足够时直接采用。官方没有、写得不清楚、疑似过期或编译对不上时，再从本地 SDK 确认。
- 不能把某个项目特定排错结论写成通用 API 规则。
- 无法从 wiki 或 SDK 证明的内容，用“建议、风险、需要验证”表达。
- 如果要求按官方/wiki 来，优先输出 API 事实，不扩展过多工程判断。

常用链接：

- ASA API Wiki: https://arkserverapi.wiki/asa/index.html
- Commands source: https://arkserverapi.wiki/asa/_commands_8cpp_source.html
- Hooks source: https://arkserverapi.wiki/asa/_hooks_8cpp_source.html
- MessagingManager: https://arkserverapi.wiki/asa/_messaging_manager_8h.html
- PluginManager source: https://arkserverapi.wiki/asa/_plugin_manager_8cpp_source.html
- Official ASA Server API resource: https://ark-server-api.com/resources/asa-server-api.31/
