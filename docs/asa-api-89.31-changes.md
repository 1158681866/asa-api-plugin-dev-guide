# ASA API V2.00 / 89.31_Changes 有效变更审计

## 审计基线

- 旧版官方 `master`：`20d685b`
- 新版官方分支：`89.31_Changes`
- 新版提交：`c6ff9c7`
- 中间提交数量：14
- 核对日期：2026-07-12
- 实测缓存对应服务端 EXE SHA256：`734d06358e83609b14cbf1d57f3ec07c9ce42bccc0c789907653ec37021e1b88`

本清单使用以下三层结果整理：

1. 忽略纯空格和排版后的官方源码差异。
2. 新旧公开头文件中的函数、字段和位域请求键差异。
3. 新增请求键与该服务端版本官方 `cached_offsets.txt` / `cached_bitfields.cache` 的实际匹配结果。

## 总体变化

| 类别 | 变化 |
|---|---|
| API 版本 | `1.22` 升为 `2.00` |
| 符号来源 | 启动时不再依赖本机 `ArkAscendedServer.pdb`，改为按服务端 EXE SHA256 使用官方缓存 |
| 工程标准 | 新头文件使用 `std::wstring_view::starts_with`，插件工程需要 C++20 |
| 公开请求键 | 旧头文件 23206 个，新头文件 23095 个；删除/替换 170 个，新增 59 个 |
| 结构体类型获取 | 113 个 `Fxxx.StaticStruct()` 由直接 offset 调用改为反射查找 `FindScriptStruct<T>()` |
| UObject 类型获取 | 大量 `StaticClass()` 改为转调 `GetPrivateStaticClass()`，底层请求键发生变化 |
| 缓存核对 | 59 个新增键中 56 个存在于对应官方缓存，3 个暂时不存在 |

## 核心运行机制变化

### 1. PDB 模式改为服务端 EXE 哈希缓存

旧版以 `ArkAscendedServer.pdb` 为基础生成或读取 offset。新版改为：

1. 计算 `ArkAscendedServer.exe` 的 SHA256。
2. 从 `AutomaticCacheDownload.DownloadCacheURL` 查询 `<exe-sha256>.zip`。
3. 验证本地缓存元数据、offset 文件和位域文件。
4. 下载新缓存时使用独立 generation 目录，验证成功后再切换。
5. 下载失败但本地有已验证缓存时，重试后继续使用本地缓存。
6. 自动下载关闭且没有匹配缓存时，API 会等待而不是继续使用错误缓存。

因此插件兼容性现在必须以“当前服务端 EXE 对应缓存”为准，不能只看头文件。

### 2. offset 基址计算改变

`Offsets.cpp` 不再把函数地址基址额外加上 PE 的 `BaseOfCode`，数据地址也不再额外加 `.data` 节 VirtualAddress。新版缓存中的值按模块映像基址解释。

使用 AsaApi `NativeCall` / 字段包装的插件会自动跟随；自行保存、计算或手写 offset 的插件需要重新核对。

### 3. 新增 `HooksDoNotThrow`

API 配置新增：

```json
"HooksDoNotThrow": false
```

默认关闭时，缺失 offset 仍会记录具体键名、等待并抛出异常。开启后 `GetAddress()` / `GetDataAddress()` 返回空地址，主要用于开发阶段收集启动期缺失项，不应当作插件继续运行的通用兜底。

### 4. 缓存文件验证加强

新增检查包括：

- 文件必须存在且非空。
- 键长度、条目数量和剩余字节合法。
- 禁止重复键。
- 下载文件落盘、Flush 和替换过程更严格。
- generation 目录名和相对路径经过校验。

### 5. HTTP 下载行为变化

`Requests` 新增：

```cpp
DownloadFile(url, localPath, headers, maximumBytes)
DownloadFile(url, localPath, headers, maximumBytes, lastModified)
GetFileLastModified(url, lastModified)
```

同时调整为：

- HTTPS 严格验证证书，并加载 Windows ROOT 证书库。
- 最多跟随 5 次安全重定向。
- HTTPS 不允许被重定向降级为 HTTP。
- 跨域重定向不继续携带 Authorization、Cookie、Host 等敏感头。
- 支持下载大小和总时间限制。
- 校验 `Content-Length`，支持读取 `Last-Modified`。

## 编译和基础类型变化

### 1. C++20

`FindScriptStruct()` 使用 `std::wstring_view::starts_with`。使用当前官方头文件编译的工程应设置：

```text
/std:c++20
```

### 2. `TSoftObjectPtr`

新版补全了更接近原生布局的 `TSoftObjectPtr`：

- 内部保存 `FSoftObjectPtr`。
- 新增默认构造、`FString` 路径构造和宽字符串路径构造。
- `Get()` 改为 `const`。
- 新增 `LoadSynchronous()`。
- 新增 `ToSoftObjectPath()`。
- 增加布局大小断言。

### 3. `TArray`

`ResizeForCopy()` 从 `FORCENOINLINE` 改为 `FORCEINLINE`。接口参数没有改变，但编译后的内联行为可能不同。

## `StaticStruct()` 变化

113 个结构体不再直接请求 `Fxxx.StaticStruct()`，而是统一使用：

```cpp
FindScriptStruct<Fxxx>()
```

相关辅助函数也已调整：

- `GetStructSize<T>()`
- `AsaApi::IApiUtils::AllocateStruct<T>()`
- `AsaApi::IApiUtils::FreeStruct<T>()`

它们现在通过 `Global.StaticFindObject(...)` 查找反射结构，不再要求每个结构体都有独立 `StaticStruct()` offset。

## `StaticClass()` / `GetPrivateStaticClass()` 变化

新版大量修改了 UObject 类型获取入口：

- 35 个旧的直接 `X.StaticClass()` 请求键被删除或改为包装转接。
- 新增 27 个 `X.GetPrivateStaticClass()` 请求键。
- 部分类仍保留直接 `StaticClass()`，部分类改为 `StaticClass() -> GetPrivateStaticClass()`。
- 同一份新头文件中声明的入口，不保证当前服务端缓存一定已有对应键。

这类改动会在重新编译后改变 DLL 实际请求的 offset，即使插件源码仍写着相同的 `X::StaticClass()`。

本次对应官方缓存中，新增的 `AShooterCharacter.GetPrivateStaticClass()` 暂时不存在，而 `AShooterCharacter.StaticClass()` 存在。因此涉及人类角色类型扫描的插件需要检查最终 DLL 实际嵌入了哪个键。

## 主要函数签名变化

### 玩家、角色和建筑

| 旧接口 | 新接口/行为 |
|---|---|
| `AShooterPlayerController.GetPlayerCharacter()` 直接 NativeCall | 改为包装转调 `BaseGetPlayerCharacter()` |
| `BaseGetPlayerCharacter()` 返回 `AActor*` | 返回 `AShooterCharacter*` |
| `ServerRequestInventoryUseItem_Implementation(..., FItemNetID)` | 增加 `int SlotIndex` |
| `ServerRequestPlaceStructure_Implementation(...)` | 旧声明被注释，新增 `ServerRequestPlaceStructure(...)` |
| `AShooterCharacter.TryLaunchMountedDino()` | 增加 `bool bIsSecondary` |
| `APrimalCharacter.NetUpdateTribeName_Implementation(...)` | 旧声明被注释，新增 `NetUpdateTribeName(...)` |
| `APrimalDinoCharacter.GetPrimalDinoCharacterSparseClassData(...)` NativeCall | 改为通过 `ClassPrivateField()->GetSparseClassData(...)` 获取 |
| `APrimalStructure.GetPrimalStructureSparseClassData(EGetSparseClassDataMethod)` | 改为无参数版本 |
| `AShooterGameState.ForceNetUpdate(bool,bool,bool)` | 派生类专用声明移除，可用继承的 `AActor` 版本时应确认最终请求键 |
| `AShooterPlayerController.GetPlayerInventoryComponent()` | 当前头文件已注释 |
| `ClientUnlockExplorerNote_Implementation(...)` | 当前头文件已注释 |
| `UObject.FindFunctionChecked(...)` | 当前头文件已注释；官方工具代码改用 `ClassPrivateField()->FindFunctionByName(...)` |

新增接口包括：

- `AShooterGameMode.GetTribeIDOfPlayerID(...)`
- `APrimalCharacter.PlayerCommand(...)`
- `APrimalCharacter.PlayerCommand_Implementation(...)`
- `AMissionType` 及任务完成消息接口

### 库存和物品

| 接口 | 新增/变化参数 |
|---|---|
| `UPrimalItem.AddNewItem(...)` | 增加 `bDontBroadcastItemUpdateEvents`、`UWorld* World` |
| `UPrimalItem.AddToInventory(...)` | 增加 `bDontBroadcastItemUpdateEvents` |
| `UPrimalItem.IncrementItemQuantity(...)` | 增加 `bDontBroadcastItemUpdateEvents` |
| `UPrimalInventoryComponent.AddItem(...)` | 增加 `bDontBroadcastItemUpdateEvents` |
| `IncrementItemTemplateQuantity(...)` | 增加 `bDontBroadcastItemUpdateEvents` |
| `GetItemOfTemplate(...)` | 增加 `IgnoreItem`、`IgnoreClass` |
| `GetItemTemplateQuantity(...)` | 增加 `IgnoreClass` |
| `RemoteInventoryAllowAddItems(...)` | 增加额外最大访问距离 |
| `RemoteInventoryAllowRemoveItems(...)` | 增加最大允许距离偏移 |
| `SetCustomItemData(...)` | 参数从 `const FCustomItemData*` 改为 `FCustomItemData*` |
| `HasCustomItemData(...)` | 从头文件内遍历改为原生 `NativeCall` |

所有直接调用这些接口的插件都需要按新参数重新编译并检查业务默认值。

## 结构体变化

`FPrimalPlayerCharacterConfigStructReplicated` 发生以下变化：

- 增加 8 字节对齐声明。
- 新增 `DynamicFaceMaterialBytes[21]`。
- 新增 `DynamicFaceIndex[3]`。
- 多个 `FieldArray` 访问器从返回临时包装改为返回引用。
- 赋值运算符返回类型和右值版本发生变化。
- `StaticStruct()` 改为 `FindScriptStruct<T>()`。

当前头文件中还存在需要谨慎验证的位宽声明：

- 三个成员本体仍是 `__int64`，对应访问器却返回 `long&`；Windows 下 `long` 为 32 位。
- `AShooterGameMode::GetTribeIDOfPlayerID` 的 C++ 参数写为 `unsigned long`，其 NativeCall 键标记为 `unsigned__int64`。

使用这些字段或函数前应等待官方修正或结合当前服务端缓存与实际对象布局验证，不能只按表面类型直接读写。

## 新头文件与当前官方缓存不一致的键

59 个新增请求键中，下列 3 个在本次服务端 EXE 对应官方缓存里不存在：

```text
APrimalCharacter.PlayerCommand(FString&)
APrimalCharacter.PlayerCommand_Implementation(FString&)
AShooterCharacter.GetPrivateStaticClass()
```

这说明“官方新头文件存在”仍不等于“当前运行缓存可调用”。后续官方更新缓存后结果可能变化，应始终按目标服务端日志中的 EXE SHA256 重新核对。

## 插件迁移顺序

1. 固定旧、新 SDK commit。
2. 生成忽略纯格式变化的版本差异。
3. 提取插件源码实际使用的函数、字段、位域和 Hook。
4. 用新头文件和同源重建的 `AsaApi.lib` 编译。
5. 从新 DLL 提取实际嵌入的请求键。
6. 下载目标服务端 EXE SHA256 对应的官方缓存。
7. 对照 `cached_offsets.txt` 和 `cached_bitfields.cache`。
8. 缺失项优先换成语义等价且缓存存在的官方入口。
9. 再编译并确认旧键消失、新键全部命中。
10. 最后进行上服功能测试。

## WcTribeCleaner 对照结果

WcTribeCleaner 命中了两项实际变化：

1. `GetPlayerCharacter()` 改为转调 `BaseGetPlayerCharacter()`。
2. `AShooterCharacter.GetPrivateStaticClass()` 不在当前缓存中，离线角色扫描改为使用存在于缓存的 `AShooterCharacter.StaticClass()`。

修复后的 DLL 实际包含 26 个 ASA 请求键：25 个普通 offset、1 个位域，全部能在目标缓存命中，缺失数为 0。
