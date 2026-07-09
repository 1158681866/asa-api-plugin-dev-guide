# 稳定性建议

本页是稳定性评估指南，不是 ASA API Wiki 的接口规范。具体插件是否需要使用某类 Hook 或 native call，应按本地 SDK、插件目标、调用频率和服务器实测判断。

## 需要重点评估的操作

- 大范围 actor 扫描
- 高频全局 Hook
- 递归访问 UObject 路径或 Outer 链
- 会触发蓝图、事件、复制同步的 setter / sync 调用
- 全局脚本派发 Hook
- Hook 内大量日志
- Hook 内复杂 IO
- 循环里频繁 `ForceNetUpdate()`
- 在 `API::Requests`、自建 `std::thread`、异步 HTTP 回调等非游戏主线程里访问 `UWorld`、玩家控制器、背包、物品、恐龙、结构等游戏对象，或调用 `GiveItem`、脚本事件、网络同步等游戏 API

这些操作不是一概禁止。采用前应记录：

- 为什么业务上需要它。
- 触发频率大概是多少。
- 作用范围如何限制。
- 如何通过日志或测试证明它生效。
- 出问题时如何关闭或回滚。

如果目标是“找某个位置附近的对象”，优先评估官方/API 提供的空间范围查询，例如 `AsaApi::GetApiUtils().GetAllActorsInRange(...)` 或已确认签名的 octree 查询。除非范围查询无法满足类过滤、对象类型或版本兼容需求，否则不建议先全图 `GetAllActorsOfClass(...)` 再按距离过滤。范围查询也需要限制触发时机、半径、重试次数，并在异常时停止本轮任务。

## 风险来源

### 对象路径和 Outer 链

路径类函数可能沿 UObject Outer 链继续访问对象。对象生命周期不稳定时，风险会被放大。

### setter / sync 调用

一些看起来只是“改数值”或“同步状态”的函数，可能触发：

- 状态变化事件
- 蓝图逻辑
- UI 更新
- 复制同步
- 其他插件 Hook

### 高频全局 Hook

触发频率越高，插件里的小成本越容易被放大，也更容易造成服务器无响应。是否可接受取决于逻辑复杂度、调用频率和服务器负载。

### 异步回调线程

`API::Requests::CreateGetRequest/CreatePostRequest` 会开后台线程执行 HTTP 请求，回调不等于游戏主线程。HTTP 回调里适合做网络结果检查、JSON 解析和构建纯数据任务，不适合直接读写 `UWorld`、玩家控制器、背包或物品。

需要调用 `AShooterPlayerController::GiveItem`、修改背包、查找在线玩家、触发脚本或同步时，应把纯数据任务投递回主线程路径，例如 `API::Timer::Get().DelayExecute(..., delay=0, task)`，再在 timer 回调里做游戏对象操作。否则可能出现物品已发出但服务器无响应、玩家断联或状态损坏。

Timer 回调仍然属于插件代码边界，不能假设 AsaApi 会替插件吞掉所有异常。`DelayExecute/RecurringExecute` 里如果会调用 `NativeCall`、`GetNativePointerField`、`StaticClass/GetPrivateStaticClass`、`UGameplayStatics::GetAllActorsOfClass`、发物品、库存刷新或网络同步，建议在回调入口包 `try/catch`，日志写清当前阶段并停止本轮重试。ASA 更新后 offsets 缺失时，`API::Offsets::GetAddress()` 可能抛 C++ 异常；不捕获会冒泡到 `API::Timer::Update()`，表现为服务器崩溃。

## 选型方法

- 先确认是否已有更贴近业务事件的 API 或 Hook。
- 目标对象能从 Hook 参数获得时，优先评估该对象是否足够满足需求。
- 如果需要重试，给重试次数、时间窗口和日志。
- 如果需要 timer 或高频 Hook，先估算每次执行成本。
- 给高风险或争议性功能加配置开关，便于隔离测试。
- 对与其他插件共享的调用链，记录兼容风险和关闭方式。

## 日志策略

好日志：

```text
命令#12 阶段=保存选择前
命令#12 阶段=保存选择后，结果=成功
事件处理 阶段=字段写入前
事件处理 阶段=字段写入后
```

坏日志：

```text
每 tick 输出所有 NPC
每次高频事件都输出完整对象信息
循环里刷几百行无筛选日志
```
