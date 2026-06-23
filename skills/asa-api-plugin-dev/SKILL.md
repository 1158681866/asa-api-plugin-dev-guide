---
name: asa-api-plugin-dev
description: ASA API / ArkServerApi 插件开发通用技能。用于 Ark Survival Ascended AsaApi C++ 插件的创建、修改、审查、排错、测试、打包；触发场景包括 ASA API 插件、ArkServerApi/AsaApi Hook、聊天命令、配置文件、游戏内通知/聊天消息、崩服日志、服务器无响应、插件打包、与其他 ASA 插件兼容。
---

# ASA API 插件开发

用于 Ark Survival Ascended 的 AsaApi C++ 插件开发。保持通用，不假设固定工作区、插件名、SDK 目录、服务器机器或用户个人路径。

## 开始前

1. 先从当前项目、工程文件、include 路径、打包脚本或用户说明里确认插件根目录和本地 AsaApi SDK 路径。
2. 改代码前先读现有实现。搜索符号、Hook、配置字段、崩溃关键字、旧逻辑时优先用 `rg`。
3. 每个引擎/API 符号先对照本地 AsaApi 头文件。本地没有或不确定时，再查 ASA API wiki：`https://arkserverapi.wiki/asa/index.html`。
4. 不猜 Hook 签名、不猜字段名。必须 grep 本地头文件确认原生函数、封装函数或字段。
5. 行为改动要同步更新代码、默认配置、测试、包内文件和文档。
6. 完成后编译、跑已有测试、打包，并报告产物路径和 DLL 时间。

## 按需读取参考

只打开当前任务需要的参考文件：

- `references/api-lookup.md`：SDK / wiki 查询、Hook 签名确认。
- `references/stability.md`：崩服/无响应风险红线和稳定写法。
- `references/messaging.md`：聊天、服务器消息、屏幕通知接口区别。
- `references/config-and-packaging.md`：配置、测试、MSBuild、打包检查。
- `references/debugging.md`：崩溃日志、无 crash 无响应、阶段日志、远程服务器排错。

## 硬规则

- 除非用户明确接受性能风险且没有事件/Hook 替代，否则不要做大范围扫描或高频全局 Hook。
- 不要随便对游戏对象调用会递归访问路径、Outer 链、脚本派发、状态同步的高风险函数；优先用 Hook 参数里已经给出的对象、稳定 ID、已验证字段。
- 会触发蓝图、脚本、网络同步或其他插件链路的调用都按高风险处理。能用更小范围的字段写入并已验证时，优先用小范围方案。
- 主方案变更后，不保留无用兜底系统、旧 Hook、废弃配置字段。
- 服务器不在本机时，不要声称“已上服验证”。只能说明本地编译/测试/打包已通过，并告诉用户服务器上要看哪些日志或效果。
- Debug 日志要有目标。发布前删除或用配置开关控制噪声日志。

## 常用流程

1. 阅读插件结构：源码、核心配置、测试、文档、打包脚本。
2. 在本地头文件或 wiki 中确认相关 API 符号。
3. 做最小且稳定的代码/配置/文档/测试改动。
4. 编译 Release。优先使用项目现有构建方式；Windows 常见方式是 MSBuild，参数为 `Configuration=Release`、`Platform=x64`。
5. 运行已有单元测试或 core tests。
6. 如果有打包脚本，执行打包脚本。
7. 检查包目录里是否有 DLL、`PluginInfo.json`、配置和项目要求的文档。
8. 向用户说明改了什么、怎么验证、包目录、DLL 时间，以及服务器上还需要测试什么。

## 设计倾向

优先使用事件驱动 Hook，尤其是 Hook 参数直接给出目标对象的接口。优先用一次性逻辑或短时间有上限的重试，避免靠 timer 扫世界。玩家可见文字、颜色、倍率尽量配置化。优先考虑和其他插件共存，不要为了“看起来更官方”去调用会触发宽泛脚本链的函数。
