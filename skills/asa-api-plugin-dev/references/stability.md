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

### 延迟生成的死亡库存与防复制

- 死亡恢复不能假设角色 `Die` Hook 返回前后立即存在独立死亡包。原角色库存可能先作为尸体库存继续存在，数分钟后才转换为 `APrimalStructureItemContainer` 或死亡包。
- 在调用原生 `Die` 前，把确切来源库存、尸体弱引用和玩家/角色标识绑定到快照，并持久化可重新解析的尸体或 Actor 标识。用于捕获同步/下一 Tick 掉包的完整 pending 关联可以短时释放，但不持有物品字节的轻量精确绑定至少保留到快照过期或来源清理，不能把几秒 pending 作为延迟转包的唯一桥梁。
- 当前 SDK 若提供 `UPrimalInventoryComponent.DropInventoryDeposit(...)` 及 `APrimalStructureItemContainer** DepositStructureResult`，确认当前版本签名和输出参数语义后，可以把成功返回的实际 deposit structure 作为精确切换点；底层 `NativeCall` 仍要隔离并做最小实机验证。`BPDropInventoryDeposit_Get` 只能作为辅助兼容，不能替代精确来源绑定。
- 延迟转包时异步持久化实际死亡包路径。服务重启丢失运行时弱引用后，优先按持久化 Actor 路径重解析；按玩家 ID 扫描的兜底必须唯一匹配该快照，不能随意选择同一玩家的旧尸体或旧包。
- 普通恢复会复制原包物品时，尸体库存与后续死亡包属于同一防复制来源。无法验证或清理任一真实来源时失败关闭；只有显式管理员强制操作可越过并留下审计。数据库中的死亡包路径为空不能直接解释为“不需要清理”或 Hook 失败。

生成头里的 C++ 方法签名、模板类型和 `NativeCall` 符号键必须作为同一 ABI 契约核对。代码通过 `/Zs`、Release 编译或链接，只能证明 C++ 表面类型可用，不能证明运行时入口会按同一对象布局解释参数；字符串解析成功或 getter 能回读，也不能替 setter、复制构造、引用计数和引擎生命周期背书。发现 wrapper 参数类型与符号键描述不一致、生成类型布局不完整或版本来源混用时，先停止调用并核对当前 SDK、PDB/反汇编或已验证实现。必须上服实验时，每轮只测试一个对象和一个字段/调用，使用管理员显式入口、默认关闭、阶段日志和失败后停止自动重试；不要把多个身份字段或 setter 一次性并入插件启动、周期重建或批量对象创建流程。

范围、部落查询、排序键缓存、跨 Tick Actor 队列和级联销毁规则见 [游戏对象安全](game-object-safety.md)。

库存奖励、商店、礼包类功能发放资源/消耗品时，不要只因为 SDK 里有某个物品或库存函数就默认使用。`UPrimalItem::AddNewItem(...)`、`UPrimalInventoryComponent.IncrementItemTemplateQuantity(...)` 等都依赖当前服务器 AsaApi offsets，可能随 ASA/AsaApi 版本缺失。选择方案时先确认目标：如果奖励必须进某个容器库存，需要逐个验证库存组件接口；如果只是给玩家奖励，优先评估成熟插件常用的 `AShooterPlayerController.GiveItem(...)` 玩家背包链路。需要品质、耐久、蓝图属性或非堆叠装备时，再评估创建物品对象路径，并把 NativeCall 阶段日志写细。

## 线程与游戏对象

AsaApi `API::Timer::RecurringExecute(..., async=false)` 通过 API timer update 触发，适合做轻量调度；`API::Requests::CreateGetRequest/CreatePostRequest` 会开后台线程，HTTP 回调不应直接操作游戏世界对象。

推荐模式：

- HTTP 回调只做网络结果检查、JSON 解析、构建纯数据任务。
- 需要读写 `UWorld`、查找在线玩家、调用 `AShooterPlayerController::GiveItem`、修改背包或触发游戏同步时，把纯数据任务投递回主线程路径，例如 `API::Timer::Get().DelayExecute(..., delay=0, task)`。
- 主线程任务里再做对象查找和游戏 API 调用，避免物品已发出但服务器无响应、断联或出现难定位状态损坏。
- Timer 回调不会替插件吞掉所有异常。`DelayExecute/RecurringExecute` 内如果会调用 `NativeCall`、`GetNativePointerField`、`StaticClass/GetPrivateStaticClass`、`UGameplayStatics::GetAllActorsOfClass`、发物品、库存刷新或网络同步，入口应包 `try/catch`，日志写清阶段并停止本轮重试。ASA 更新后 offsets 缺失时，`API::Offsets::GetAddress()` 可能抛 C++ 异常；不捕获会冒泡到 `API::Timer::Update()` 导致崩服。
- 如果必须在后台线程处理耗时逻辑，只处理纯数据、HTTP、文件或数据库结果，不持有或跨线程使用 `UObject`/`AActor` 指针。

调用外部 AI、Webhook 或其他可能持续数秒的 HTTP 服务时，除“不能在游戏线程阻塞”外，还必须验证请求与插件卸载的生命周期。异步 API 如果使用分离线程、全局完成队列或保存指向插件代码的 `std::function`，而卸载路径不能逐请求取消并等待完成，那么 `plugins.unload` 后回调可能落到已释放 DLL。遇到这种实现时，不要直接用于外部长请求；改用插件自管且可停止、可 `join` 的工作线程/WinHTTP 会话，或生命周期独立于插件 DLL 的本机 sidecar。`Plugin_Unload()` 应先停止接单、取消网络句柄、唤醒并等待工作线程退出、清空完成队列，再允许 DLL 卸载。

自管异步 WinHTTP 如果把请求上下文保存在栈上，关闭 request handle 后必须等到 `WINHTTP_CALLBACK_STATUS_HANDLE_CLOSING`，并确认已经进入的回调全部退出，才能销毁上下文或允许 DLL 卸载。不能因为 `WinHttpCloseHandle()` 返回失败就跳过该屏障；这种异常路径宁可阻止卸载并保留阶段日志，也不能让可能迟到的回调访问已释放上下文或插件代码。

RCON、服务器控制台、聊天观察和定时器回调也不能未经验证就假设在同一线程。管理命令如果会启停功能、重载文件、操作请求状态或调用游戏 API，稳定写法是：命令回调只校验来源、复制纯文本并写入有界控制队列，RCON 只立即返回“已排队”；下一次游戏线程 timer 再执行状态变更、测试消息和探针。不要跨回调保存 `RCONClientConnection*`、`RCONPacket*`、`FString*` 或玩家控制器指针。`Status` 可读取定时器发布的不可变文本快照，避免为了查询状态从未知线程遍历可变容器或调用 UE API。

同一定时任务如果也能由 RCON、console 或管理员命令手动触发，必须防止重入。全图扫描、审计写入、`Destroy` Actor、发奖励、改权限或改数据库状态等任务在入口使用互斥或运行中状态；重复触发应明确跳过或排队，并在 Status/日志暴露 `running/skipped`，避免重复清理、重复发放或任务状态交错。

仅停止后台线程仍不足以证明热卸载安全。插件存在聊天、timer、RCON 或 console 回调时，应在所有入口统一经过“是否仍接单”的门闩并维护活动回调计数；卸载先关闭门闩和业务状态，再停止/join 网络线程、注销入口，最后等待活动回调归零后清空全局状态。门闩检查和活动计数必须由同一互斥边界保护，否则会出现卸载刚观察到计数为零、另一个回调随后才递增的竞态窗口。等待超时时只写阶段日志并继续等待，不可带存活回调返回让 DLL 被释放。

外部 HTTPS 请求还应确认实际启用了系统证书验证。仅有 `https://` URL 不代表底层客户端验证服务端证书；携带 API Key、Token 或玩家数据时，不使用明确关闭证书验证的请求实现。

## 评估做法

- 如果 Hook 参数直接提供目标对象，先评估它是否足够满足需求。
- 字段写入、脚本调用、同步调用都要说明验证方式。
- 初始化有延迟时，重试应有次数上限和日志。
- 延迟任务里注意对象生命周期。
- 测试期给争议性功能加配置开关。

## 插件兼容

如果其他插件在某个调用后立刻报错，先用“前/后”日志定位最后一个触发点，再评估是否需要替换、延迟、配置化或关闭该调用。

## ASA API 2.03 命令卸载

- ASA API 2.03 会在 `Plugin_Unload()` 返回后调用模块级清理，自动将该 DLL 注册的聊天、控制台、RCON 命令和命令回调置空并移出容器。
- 不要在 `Plugin_Unload()` 中再次手动执行 `RemoveChatCommand`、`RemoveConsoleCommand` 或 `RemoveRconCommand`。如果卸载操作由 `plugins.unload` 的 RCON/控制台命令触发，API 命令分发仍持有一份 `shared_ptr` 快照；插件先手动移除命令会让后续模块级清理无法把快照中的 `std::function` 置空，DLL 被释放后快照析构可能在 `CheckCommands` / `_Ref_count_obj2::_Destroy` 崩溃。
- 动态配置重载时仍可增删命令，但不能在当前命令回调栈内直接修改同一命令容器；延迟到下一 tick/timer 执行。
- 依赖上述模块级快照失效语义的插件必须把 `PluginInfo.MinApiVersion` 设为 `2.03` 或更高，并用同源 2.03+ 公共头与官方发布包中的 `AsaApi.lib` 构建。不能一边声明兼容 1.18/1.21，一边依赖仅在 2.03 才存在的卸载屏障。

