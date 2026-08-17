# 游戏对象、扫描与清理

仅在任务涉及库存、Actor 扫描、排序、批量清理、死亡包或存档级对象时读取。这里记录工程边界，不把函数名本身当作性能或生命周期保证。

## 库存快照与虚拟装饰

- 不要假设 `InventoryItemsField()` 中的每个对象都是玩家实际持有、死亡可掉落或应该持久化恢复的物品；“应用装饰”界面可能把虚拟可用外观对象混入库存组件。
- 捕获和恢复快照前，优先按序列化实例中的 `IsUnlockedCosmetic` / `IsAutoUnlocked` 标记过滤。不要把 `AllCustomCosmeticItemsField()` 成员关系或目录蓝图名作为硬排除条件，因为实体皮肤可能共享集合或蓝图族群。
- 不要把 `bIsItemSkin` 直接等同于虚拟目录项，否则会误删真实皮肤。生成头即使暴露 `UPrimalItem.bIsCustomCosmeticDisplay`，也要确认目标 AsaApi offsets 含该位字段；仅编译成功不能证明服务器可调用，缺失 offset 可能让 `GetBitFieldInternal` 直接终止进程。

## 范围与部落查询

- 业务目标是“某位置附近对象”时，优先评估官方或 API 提供的空间范围查询，例如 `AsaApi::GetApiUtils().GetAllActorsInRange(...)` 或已确认签名的 octree 查询；不要默认先全图 `GetAllActorsOfClass(...)` 再按距离过滤。
- 需要按部落 ID 获取建筑、恐龙或角色时，先确认当前 Wiki/SDK 是否提供 `UGameplayStatics::GetAllActorsOfClassInTribe(...)`，并核对当前版本的签名、`NativeCall` key 和 offset。
- 函数名只能证明存在“按部落返回结果”的入口，不能据此断言内部维护高性能索引。是否减少扫描开销要靠最小实机基准或逆向证据。
- 即使采用范围或部落查询，也要限制触发时机、半径、批量大小和重试次数，异常时停止本轮任务。

## 排序与多 Tick 批处理

- 对大型 Actor 集合按位置、高度、血量或其他 UObject 字段排序时，不要在 `std::sort` / `std::stable_sort` 比较器里反复执行 `weak.Get()`、`GetLocation()`、字段访问或 `NativeCall`。
- 先线性遍历一次，把排序键缓存到普通临时记录，再让比较器只比较数字或字符串；昂贵对象访问由 `O(N log N)` 降为 `O(N)`。真正处理前仍要重新取得弱引用并复核有效性和归属。
- 跨 Tick 队列不要长期保存裸 `AActor*`。优先使用当前 Wiki/SDK 支持的 `GetWeakReference(actor)` 保存 `TWeakObjectPtr<AActor>`，或保存可重新解析的稳定标识；不要猜测 `TWeakObjectPtr<AActor>(actor)` 构造方式。
- 每一批访问 `TargetingTeamField()`、位置、库存或 `Destroy()` 前，都重新 `weak.Get()` 并兜底跳过失效对象。支撑链、GC、Mod 蓝图和其他插件可能提前销毁队列中的对象。

## 级联销毁与二级 Actor

- 删除结构、容器或库存 Actor 后，游戏可能在后续 Tick 生成 `ADroppedItem`、死亡包、库存包或缓存结构。地基/支撑先删除时，上层工作台、保险柜、箱子也可能稍后因失去支撑而销毁并生成新包。
- 目标是“清干净资产”时，主对象删除后留短延迟，至少再做一次掉落物/缓存扫描；支撑链场景建议复查同部落结构/容器，再做最终掉落物扫描。
- 归属优先使用明确字段，例如 `ADroppedItem.AssignedToTribeID`、结构 `TargetingTeam`。不要只按距离、名称或附近最近包裹猜测归属，避免清掉其他玩家资产。
- 死亡库存的延迟绑定、防复制和失败关闭规则继续遵循 [稳定性](stability.md#延迟生成的死亡库存与防复制)。

## 非核心展示不得加载存档级数据

- 不要为了日志、Status、队列预览或名称美化，在 timer、扫描或清理链调用 `AShooterGameMode::GetOrLoadTribeData()` / `LoadTribeData()` 这类会加载或复制存档数据的接口。
- 部分 ASA 版本在启动早期或数据未稳定时可能在 `FTribeData::CopyFrom()` / `TArray<FString>::operator=()` 崩溃。展示字段读不到时使用“暂未读到”等兜底，或只读取已经在线、已加载对象上的现成安全字段。
