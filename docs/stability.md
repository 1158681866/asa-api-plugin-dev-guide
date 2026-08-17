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

库存奖励、商店、礼包类功能发放资源或消耗品时，不要只因为 SDK 里有某个物品或库存函数就默认使用。`UPrimalItem::AddNewItem(...)`、`UPrimalInventoryComponent.IncrementItemTemplateQuantity(...)` 等都依赖当前服务器 AsaApi offsets，可能随 ASA/AsaApi 版本缺失。选择方案时先确认目标：如果奖励必须进某个容器库存，需要逐个验证库存组件接口；如果只是给玩家奖励，优先评估成熟插件常用的 `AShooterPlayerController.GiveItem(...)` 玩家背包链路。需要品质、耐久、蓝图属性或非堆叠装备时，再评估创建物品对象路径，并把 NativeCall 阶段日志写细。

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

### 生成头与 `NativeCall` ABI

生成头里的 C++ 方法签名、模板类型和 `NativeCall` 符号键属于同一个运行时 ABI 契约。代码通过 `/Zs`、Release 编译或链接，只能证明 C++ 表面类型可用，不能证明引擎入口会按同一对象布局解释参数；字符串能解析、getter 有返回，也不能替 setter、复制构造、引用计数和引擎生命周期背书。

发现 wrapper 参数类型与符号键描述不一致、生成类型布局不完整或 SDK/库版本来源混用时，应先停止调用并核对当前版本的 SDK、PDB/反汇编或已验证实现。确需上服实验时，使用管理员显式入口并保持默认关闭；每轮只测试一个对象和一个字段或调用，记录调用前、调用后与 getter 回读，异常后停止自动重试。不要把多个高风险 setter 一次并入插件初始化、周期任务或批量对象创建。

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

## 游戏对象、库存与批处理

- `InventoryItemsField()` 可能混入“应用装饰”提供的虚拟外观对象。快照与恢复优先检查序列化实例的 `IsUnlockedCosmetic` / `IsAutoUnlocked`，不要只凭目录集合、蓝图名或 `bIsItemSkin` 排除；位字段还要确认当前 AsaApi offsets 存在。
- 按范围或部落查 Actor 时，先评估 `GetAllActorsInRange(...)`、octree 查询或 `UGameplayStatics::GetAllActorsOfClassInTribe(...)`。核对当前版本签名和 offset；函数名不能证明内部一定使用高性能索引。
- 排序前线性缓存位置、高度、血量等普通键，不在 `std::sort` 比较器里重复 `weak.Get()`、字段访问或 `NativeCall`。
- 跨 Tick 队列使用 `GetWeakReference(actor)` 或可重新解析标识，不长期保存裸 `AActor*`；每批处理前重新检查有效性、类型和归属。
- 删除结构/容器后，后续 Tick 可能因支撑链生成掉落物、死亡包或缓存包。主清理后延迟复查同部落对象和二级 Actor，归属使用明确字段，不按距离或名称猜测。
- 日志、Status 和队列预览不要调用 `GetOrLoadTribeData()` / `LoadTribeData()` 这类存档级加载接口；读不到展示字段时使用安全兜底。

