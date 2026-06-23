# Agent 使用说明

本仓库面向 Codex、Claude Code 等代码 Agent，目标是让 Agent 在开发 ASA API / ArkServerApi 插件时能直接遵循稳定、可验证、可发布的流程。

## 适用任务

当任务涉及以下内容时，Agent 应使用本仓库规则：

- Ark Survival Ascended AsaApi C++ 插件
- ArkServerApi / AsaApi Hook
- 聊天命令、RCON 命令、配置文件
- 游戏内消息、服务器消息、屏幕通知
- 崩服、服务器无响应、无 crash 日志排错
- 插件编译、测试、打包、发布
- 与其他 ASA API 插件兼容

## 开始前

1. 先确认当前要处理的是哪个插件项目，而不是本指南仓库本身。
2. 从工程文件、include 路径、打包脚本或用户说明里确认本地 AsaApi SDK 路径。
3. 改代码前先读现有实现。
4. 搜索符号、Hook、配置字段、崩溃关键字、旧逻辑时优先用 `rg`。
5. 每个引擎/API 符号先查本地 AsaApi 头文件；本地没有或不确定时，再查 ASA API Wiki。
6. 不猜 Hook 签名、不猜字段名。

## 必读文档

按任务类型读取对应文档，不要一次性把所有内容塞进上下文。

- 新项目/结构设计：`docs/project-structure.md`
- API / Hook 查询：`docs/api-lookup.md`
- 配置和命令：`docs/config-and-commands.md`
- 通知和聊天：`docs/messaging.md`
- 崩服/无响应排错：`docs/debugging.md`
- 高风险调用判断：`docs/stability.md`
- 编译测试打包：`docs/build-test-package.md`
- 发布前检查：`docs/release-checklist.md`

## 硬规则

- 除非用户明确接受风险且没有事件/Hook 替代，不要把大范围扫描或高频全局 Hook 当默认方案。
- 不要靠猜测调用游戏对象路径、Outer 链、脚本派发、状态同步、setter 等高风险路径。
- 任何 Hook 签名、字段名、封装函数，都必须从本地 SDK 或项目现有代码确认。
- 主方案变更后，删除旧 Hook、旧配置字段、旧文档说明、旧测试、旧日志和旧兜底路径。
- 服务器不在本机时，不要声称“已上服验证”。只能说明本地编译、测试、打包通过，并列出服务器上要验证的日志或效果。
- Debug 日志要有目的，发布前删除或受配置开关控制。

## 工作流

1. 阅读当前插件结构：源码、配置、测试、文档、打包脚本。
2. 确认相关 API / Hook / 字段来源。
3. 做最小、稳定、可回滚的改动。
4. 同步更新默认配置、配置说明、测试、README 和发布包。
5. 编译 Release。
6. 运行已有测试。
7. 执行打包脚本。
8. 检查包目录是否包含 DLL、`PluginInfo.json`、`config.json`、配置说明文件和 README。
9. 回复用户时说明改动、验证结果、包目录、DLL 时间，以及服务器上还要测什么。

## 配置说明标准

ASA API 插件常见做法是：

```text
config.json
config说明.json 或 config-commented.json
```

`config.json` 是插件读取的严格 JSON。

说明文件通常是复制一份真实配置结构后，在字段旁写说明。文件名和 `.json` 后缀不是标准；真正的标准是说明内容：

- 保留接近真实 `config.json` 的结构。
- 字段旁写短注释。
- 下方补字段说明。
- 倍率、概率、时间写计算公式和示例。
- 写清楚修改后如何重载或重启。
- 写清楚插件真正读取的是 `config.json`。

## 禁止写入指南的内容

本仓库是通用指南。不要把某个服务器、某个私有插件、某次冲突事故、某个作者习惯直接写成通用标准。

如果经验来自具体事故，先抽象成通用原则，再写入文档。
