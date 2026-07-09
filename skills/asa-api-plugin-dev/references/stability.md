# 稳定性评估

本页是工程评估指南，不是 ASA API Wiki 的接口规范。ASA 服务器插件可能没有清晰 crash 栈就崩服或无响应；风险操作应可观察、可关闭、可回滚。

## 需要评估

- 大范围 actor 扫描。
- 高频全局 Hook。
- 对可能失效或临时对象调用 UObject 路径链、Outer 链函数。
- 在 Hook 里调用重型脚本、事件、网络同步函数。
- 在命令回调里调用复杂 UI、脚本或对象访问链。

## 高风险类别

- setter / sync 类调用，可能触发内部脚本、UI、复制同步或其他插件 Hook 链。
- 全局脚本 Hook，尤其当其他插件也 Hook 脚本派发时。
- 循环里反复 `ForceNetUpdate()`。
- 在 `API::Requests`、自建 `std::thread`、异步 HTTP 回调等非游戏主线程里访问 `UWorld`、玩家控制器、背包、物品、恐龙、结构等游戏对象，或调用 `GiveItem`、脚本事件、网络同步等游戏 API。

这些操作不是一概禁止。采用前说明业务必要性、触发频率、范围限制、可观测日志和回滚方式。

如果业务目标本身是“找某个位置附近的对象”，优先评估官方/API 提供的空间范围查询，例如 `AsaApi::GetApiUtils().GetAllActorsInRange(...)` 或已确认签名的 octree 查询；不要先全图 `GetAllActorsOfClass(...)` 再用距离过滤，除非范围查询无法满足类过滤、对象类型或版本兼容需求。即使使用范围查询，也要限制触发时机、半径、重试次数，并在异常时停止本轮任务。

## 线程与游戏对象

AsaApi `API::Timer::RecurringExecute(..., async=false)` 通过 API timer update 触发，适合做轻量调度；`API::Requests::CreateGetRequest/CreatePostRequest` 会开后台线程，HTTP 回调不应直接操作游戏世界对象。

推荐模式：

- HTTP 回调只做网络结果检查、JSON 解析、构建纯数据任务。
- 需要读写 `UWorld`、查找在线玩家、调用 `AShooterPlayerController::GiveItem`、修改背包或触发游戏同步时，把纯数据任务投递回主线程路径，例如 `API::Timer::Get().DelayExecute(..., delay=0, task)`。
- 主线程任务里再做对象查找和游戏 API 调用，避免物品已发出但服务器无响应、断联或出现难定位状态损坏。
- Timer 回调不会替插件吞掉所有异常。`DelayExecute/RecurringExecute` 内如果会调用 `NativeCall`、`GetNativePointerField`、`StaticClass/GetPrivateStaticClass`、`UGameplayStatics::GetAllActorsOfClass`、发物品、库存刷新或网络同步，入口应包 `try/catch`，日志写清阶段并停止本轮重试。ASA 更新后 offsets 缺失时，`API::Offsets::GetAddress()` 可能抛 C++ 异常；不捕获会冒泡到 `API::Timer::Update()` 导致崩服。
- 如果必须在后台线程处理耗时逻辑，只处理纯数据、HTTP、文件或数据库结果，不持有或跨线程使用 `UObject`/`AActor` 指针。

## 评估做法

- 如果 Hook 参数直接提供目标对象，先评估它是否足够满足需求。
- 字段写入、脚本调用、同步调用都要说明验证方式。
- 初始化有延迟时，重试应有次数上限和日志。
- 延迟任务里注意对象生命周期。
- 测试期给争议性功能加配置开关。

## 插件兼容

如果其他插件在某个调用后立刻报错，先用“前/后”日志定位最后一个触发点，再评估是否需要替换、延迟、配置化或关闭该调用。
