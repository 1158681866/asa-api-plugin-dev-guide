---
name: asa-api-plugin-dev
description: ASA API / ArkServerApi 插件开发通用技能。用于 Ark Survival Ascended AsaApi C++ 插件的创建、修改、审查、排错、测试、打包；触发场景包括 ASA API 插件、ArkServerApi/AsaApi Hook、聊天命令、配置文件、游戏内通知/聊天消息、崩服日志、服务器无响应、插件打包、与其他 ASA 插件兼容。
---

# ASA API 插件开发

用于 Ark Survival Ascended 的 AsaApi C++ 插件开发。保持 Agent 客户端中立，不假设固定工作区、插件名、SDK 目录、服务器机器、个人路径或厂商专属工具。Windows、MSVC/MSBuild 与同源 AsaApi 构件属于插件构建环境约束，不属于 Agent 平台绑定。

## 最高原则

1. 先确认当前插件根目录和实际任务边界，再读现有源码、配置、测试、文档与打包脚本。
2. API、Hook、字段和签名优先查 ASA API 官方文档或 Wiki；文档足够时停止。只有资料缺失、疑似过期或编译不一致时，才查当前项目使用的本地 SDK；最后才参考成熟插件源码。
3. 优先使用 AsaApi/ArkApi 标准封装、SDK helper 和公开安全函数。只有没有高层接口、业务必须且风险已隔离时，才使用底层字段、`NativeCall`、私有类信息或手写偏移。
4. 区分已确认 API 事实、工程判断和待实机验证内容。不确定的调用链不能写成确定结论。
5. 使用当前环境可用的仓库搜索、编辑、构建和验证能力。有 `rg` 时优先使用；没有时用 `git grep`、`Select-String` 或等价工具，不跳过门禁。
6. 服务器不在本机时，只报告本地源码、构建、测试和打包结果；不要声称已经上服验证。

## 按需读取参考

只读取当前任务需要的文件，路径均以本 Skill 目录为根：

- API、Wiki、SDK、Hook 签名与查询顺序：[API 查询](references/api-lookup.md)
- API 事实、社区结构和工程结论分级：[来源边界](references/official-api-sources.md)
- 需求边界、分层、实现、验证和发布流程：[开发流程](references/development-workflow.md)
- UObject 生命周期、线程、NativeCall、卸载与高风险实验：[稳定性](references/stability.md)
- 库存快照、Actor 查询、排序、跨 Tick 清理与级联销毁：[游戏对象安全](references/game-object-safety.md)
- 聊天、通知、广播、观察回调与跨插件兼容：[消息接口](references/messaging.md)
- MySQL、共享任务表、外部网络线程和副作用幂等：[数据库与外部系统](references/database-and-integrations.md)
- 配置、命令、测试、MSBuild、Web 配置器和 ZIP 发布：[配置与打包](references/config-and-packaging.md)
- 崩溃、无响应、远程服务器和阶段日志：[排错](references/debugging.md)
- 把项目经验抽象并更新回通用 Skill：[Skill 迭代](references/skill-evolution.md)

## 执行流程

1. **确认基线**：识别插件目录、AsaApi 版本、SDK commit、`AsaApi.lib` 来源、现有构建方式和服务器是否本机可用。版本号不变不代表头文件没有更新；按 [API 查询](references/api-lookup.md) 区分头文件修正与核心接口变更。
2. **确认入口**：为每个 Hook、命令、字段或 NativeCall 标记来源；必要时记录精确 key、参数 ABI、对象线程和生命周期。
3. **设计改动**：把纯配置/规则/状态逻辑与 AsaApi/UE 对象访问分开；高风险路径提供关闭、回滚和可观察结果。
4. **实施同步**：代码行为变化时同步默认配置、配置说明、测试、README/项目文档和包内运行文件；删除废弃字段、旧 Hook、旧日志与无用兜底。
5. **验证**：执行 `Release|x64` 构建、已有 core tests、项目打包脚本和最终 ZIP 检查。测试必须验证实际行为，不能只依赖编译成功、HTTP 200、回调计数或 UI 表象。
6. **检查产物**：区分源码修改、编译产物、本地测试目录、正式 ZIP 和真实上服验证。枚举 `build/package/` 顶层和 ZIP 条目，确认 DLL 时间、配置模板、敏感信息和 staging 清理。
7. **交付**：说明改了什么、运行了哪些验证、测试目录、正式 ZIP、DLL 时间/哈希，以及服务器侧仍需测试的命令、日志或效果。
8. **自我迭代**：判断本轮经验是通用规则还是项目经验；通用且边界清晰时更新可写、受版本控制的 Skill 权威源，项目特定内容写回项目文档。

## 必守稳定性门禁

- 只在游戏线程访问 `UWorld`、Controller、Pawn、库存和其他 UObject。网络、数据库和后台线程只处理纯数据，并通过有界队列回到游戏线程。
- 跨 Tick 保存游戏对象时使用当前 SDK 支持的弱引用或可重新解析标识；每次操作前重新取对象并校验有效性、类型和归属。
- 生成头能编译不等于 NativeCall ABI 或对象布局运行安全。高风险 setter、身份、同步和脚本调用要核对当前版本精确签名；管理员单次实验默认关闭、单变量、带阶段日志，失败后停止自动重试。
- Hook、timer、聊天、RCON、console 和异步请求都纳入卸载屏障：先停止接单，再停止/join 后台工作，等待活动回调退出，最后释放状态。不得让回调落入已卸载 DLL。
- 修改命令容器、重载配置或切换运行状态时考虑回调线程和重入。管理命令可先复制纯文本入控制队列，再由下一次游戏线程 timer 执行。
- 本服显示、服务器广播、AsaApi 观察回调、跨服/机器人转发和远端接收是不同验收层；不得用前一层成功推断后一层成功。

## 配置与发布底线

- `PluginInfo.Version` 是插件版本，`MinApiVersion` 是最低 AsaApi 版本，二者独立；新插件通常从 `Version: 1.0` 开始。
- `config.json` 保持严格 JSON；`config说明.json` 用中文解释全部公开字段、范围、单位、特殊值和生命周期命令。用户只要求改某一区域时，不顺带重构其他结构。
- 服主常调玩法参数优先配置化；内部实现参数、临时排错参数和错误配置风险高的参数默认不暴露。
- `build/package/<Plugin>/` 是本地测试目录，可以保留本地配置和开发文档副本；同级 Release ZIP 才是对外产物。
- 正式 ZIP 只包含 DLL、`PluginInfo.json`、`config.json`、`config说明.json` 及确认必需的运行文件。通过临时 staging 或显式白名单构建，公开配置脱敏且保持安全默认值，不覆盖本地测试配置。
- 玩家与服主可见文字使用服务器真实业务称呼，并为必要英文配置名补充中文含义。

## Skill 维护边界

- 只有能覆盖多类 ASA 插件、服务器环境或问题类型的结论才进入通用 Skill；私有路径、单服业务、聊天话术、经济数值、奖励表和未脱敏日志留在项目内。
- 先定位受版本控制的权威源，不猜任何 Agent 客户端安装目录。当前只有部署副本或只读副本时，生成候选补丁或待同步项，不把部署副本冒充公共来源。
- 修改规则后搜索旧写法和反向结论；权威源位于 Git 仓库时执行 `git diff --check`。同步客户端部署副本前检查本地差异，有冲突时三方合并或保留冲突，不整目录强制覆盖。
