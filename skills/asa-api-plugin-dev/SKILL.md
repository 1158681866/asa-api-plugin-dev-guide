---
name: asa-api-plugin-dev
description: ASA API / ArkServerApi 插件开发通用技能。用于 Ark Survival Ascended AsaApi C++ 插件的创建、修改、审查、排错、测试、打包；触发场景包括 ASA API 插件、ArkServerApi/AsaApi Hook、聊天命令、配置文件、游戏内通知/聊天消息、崩服日志、服务器无响应、插件打包、与其他 ASA 插件兼容。
---

# ASA API 插件开发

用于 Ark Survival Ascended 的 AsaApi C++ 插件开发。保持通用，不假设固定工作区、插件名、SDK 目录、服务器机器或个人路径。

## 开始前

1. 先从当前项目、工程文件、include 路径、打包脚本或任务说明里确认插件根目录和本地 AsaApi SDK 路径。
2. 改代码前先读现有实现。搜索符号、Hook、配置字段、崩溃关键字、旧逻辑时优先用 `rg`。
3. 每个引擎/API 符号先按当前项目使用的本地 AsaApi SDK 确认；wiki 用于检索和交叉确认：`https://arkserverapi.wiki/asa/index.html`。
4. 不确定的 Hook 签名、字段名、调用链必须标记为“待确认”，不要写成确定结论。
5. 行为改动要同步更新代码、默认配置、测试、包内文件和文档。
6. 完成后编译、跑已有测试、打包，并报告产物路径和 DLL 时间。
7. 区分 API 事实、社区常见结构和工程判断；不要把项目特定问题写成通用规则。

## 按需读取参考

只打开当前任务需要的参考文件：

- `references/api-lookup.md`：SDK / wiki 查询、Hook 签名确认。
- `references/official-api-sources.md`：区分 API 事实、社区常见结构和工程判断。
- `references/development-workflow.md`：需求边界、代码分层、验证和发布流程。
- `references/stability.md`：崩服/无响应风险建议和稳定写法。
- `references/messaging.md`：聊天、服务器消息、屏幕通知接口区别。
- `references/config-and-packaging.md`：配置、测试、MSBuild、打包检查。
- `references/debugging.md`：崩溃日志、无 crash 无响应、阶段日志、远程服务器排错。

## 工程判断

- 大范围扫描、高频全局 Hook、脚本派发、状态同步、setter 等做法需要说明业务必要性、触发频率、范围限制、可观测日志和回滚方式。
- 不靠猜测确定游戏对象路径、Outer 链、脚本派发、状态同步、setter 等调用链；不确定时先查 SDK、wiki 或现有项目代码。
- 会触发蓝图、脚本、网络同步或其他插件链路的调用要写清楚验证方式。
- 主方案变更后，不保留无用兜底系统、旧 Hook、废弃配置字段。
- 服务器不在本机时，不要声称“已上服验证”。只能说明本地编译/测试/打包已通过，并告诉用户服务器上要看哪些日志或效果。
- Debug 日志要有目标。发布前删除或用配置开关控制噪声日志。

## 常用流程

1. 阅读插件结构：源码、核心配置、测试、文档、打包脚本。
2. 在本地头文件或 wiki 中确认相关 API 符号。
3. 做范围清晰、可验证、可回滚的代码/配置/文档/测试改动。
4. 编译 Release。优先使用项目现有构建方式；Windows 常见方式是 MSBuild，参数为 `Configuration=Release`、`Platform=x64`。
5. 运行已有单元测试或 core tests。
6. 如果有打包脚本，执行打包脚本。
7. 检查包目录里是否有 DLL、`PluginInfo.json`、配置和项目要求的文档。
8. 交付时说明改了什么、怎么验证、包目录、DLL 时间，以及服务器上还需要测试什么。

## 设计倾向

选型时先说明业务目标、可用 API、调用频率、目标对象来源和验证方式。事件 Hook、短时重试、字段写入、timer、全局 Hook 都只是工具；是否合适取决于插件目标和实测结果。玩家可见文字、颜色、倍率尽量配置化，方便不同服务器调整。
