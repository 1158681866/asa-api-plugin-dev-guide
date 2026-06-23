# ASA API 插件开发指南

面向 Ark Survival Ascended 的 AsaApi / ArkServerApi C++ 插件开发指导项目。

这个仓库不是某一个插件的说明书，而是一套通用开发规范、排错流程、稳定性建议和项目模板。目标是让 ASA API 插件从“能编译”走向“能上服、能排错、能维护、能发布”。

## 适用范围

- ASA AsaApi C++ 插件开发
- ArkServerApi / AsaApi Hook 接入
- 聊天命令、RCON 命令、配置热重载
- 游戏内聊天消息、服务器消息、屏幕通知
- 崩服、无响应、无 crash 日志排错
- 插件打包、版本发布、上服测试
- 与其他 ASA 插件共存

## 不适用范围

- UE Mod 蓝图开发
- 非 AsaApi 的独立服务端程序
- 未经验证的内存偏移硬改
- 未经验证的高频 Hook 或大范围扫描方案

## 推荐阅读顺序

1. [使用方式](docs/usage.md)
2. [Agent 使用](docs/agent-usage.md)
3. [开发原则](docs/principles.md)
4. [环境与 SDK](docs/environment.md)
5. [项目结构](docs/project-structure.md)
6. [官方 API 来源与经验边界](docs/official-api-sources.md)
7. [API 与 Hook 查询](docs/api-lookup.md)
8. [稳定性建议](docs/stability.md)
9. [配置与命令](docs/config-and-commands.md)
10. [通知与聊天](docs/messaging.md)
11. [测试、编译与打包](docs/build-test-package.md)
12. [排错手册](docs/debugging.md)
13. [发布检查清单](docs/release-checklist.md)
14. [维护规范](docs/maintenance.md)

## 快速约定

- 先查本地 SDK 头文件，再查 wiki。
- 区分 API 事实、社区常见结构和工程建议。
- 不猜 Hook 签名。
- 不把大范围扫描当默认方案。
- 不把高频全局 Hook 当默认方案。
- 对会触发额外对象访问、脚本事件、网络同步或其他插件链路的调用保持克制。
- 任何行为变更都同步更新：代码、配置、测试、文档、包目录。
- 服务器不在本机时，本地只能证明“编译/测试/打包通过”，不能声称“上服验证通过”。

## 官方/常用资料

- ASA API Wiki: https://arkserverapi.wiki/asa/index.html
- ArkServerApi/AsaApi GitHub: https://github.com/ArkServerApi/AsaApi

## 仓库状态

这是指导项目，可作为新插件开发前的通用参考，也可复制 `templates/plugin-skeleton` 作为新插件起点。

它本身不是服务器插件。仓库内置 Codex skill：`skills/asa-api-plugin-dev`，可用 `scripts/install-skill.ps1` 安装到本机 Codex。Codex、Claude Code 等 Agent 也可以直接读取 `AGENTS.md` / `CLAUDE.md`；本仓库负责承载完整文档、模板和 Agent 规则。

## 维护方式

- 用 issue 记录排错和文档补充。
- 用 PR 记录结构化修改。
- 新增经验时优先更新已有专题文档，避免重复散落。
- 私有仓库也按可发布标准管理，不提交 token、密码、服务器私密地址或未脱敏日志。
