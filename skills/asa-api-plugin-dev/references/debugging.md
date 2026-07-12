# 排错

## 有 crash 栈

收集或检查：

- `crashcallstack.txt`
- 最新 `ArkApi_*.log`
- 同时间段服务器游戏日志
- 插件 DLL 时间、配置和包路径
- ASA 服务端版本和 AsaApi 版本

把栈映射到插件阶段：加载 Hook、命令回调、timer、事件 Hook、资源/库存、通知。

## API 更新后的兼容处理

### 默认流程：普通新插件或常规升级

正常情况下不要把兼容检查复杂化，按下面做即可：

1. 使用目标服务器对应的最新版官方 SDK。
2. 确保头文件和 `AsaApi.lib` 来自同一版本；如果只是切换了 SDK 分支，要先重新生成库。
3. 按新 SDK 要求完成 Release 编译。
4. 上服确认插件能加载，并测试本插件实际使用的核心功能。

只要没有 offset 报错、编译/签名异常或功能异常，检查到这里就停止。某个 API 版本的完整变化清单只需集中整理一次，之后所有插件复用，不要让每个插件重复分析整套 API。`GetPlayerCharacter()` / `BaseGetPlayerCharacter()` 只是 89.31 迁移案例，不是所有插件都要专门检查的固定项目。

### 何时才做深度检查

仅在以下情况按需做 DLL 与官方缓存的全量对照：

- 日志出现 `Failed to get the offset of '具体函数名'`。
- API 大版本刚发布，官方缓存仍可能不完整。
- 插件出现只能在运行时复现的兼容崩溃或功能异常。
- 删除建筑、修改库存等高风险插件准备正式发布，且需要额外做一次完整兼容审计。
- 用户明确要求完整兼容审计。

深度检查步骤：

- 先核对报错时间是否早于新版 DLL 的编译/部署时间，避免拿旧日志误判新包。
- 从插件工程文件确认实际 include 和 link 的 SDK 目录，再记录该 SDK 的 remote、branch、commit 和工作区状态；不要只检查另一个“看起来最新”的 SDK 副本。
- 确认目标分支的 `AsaApi.lib` 已重新生成，并与头文件同源。
- 检查插件实际使用的 `NativeCall`、`xxxField()` / `GetNativePointerField`、BitField、Hook 签名、`StaticClass` / `GetPrivateStaticClass`，以及 AsaApi helper 内部的间接调用。
- 编译后搜索 DLL 中实际嵌入的 offset 字符串，确认产物请求的是旧函数还是新函数。
- 如果 API 日志给出了当前服务端 EXE 的 SHA256，可从 AsaApi 配置中的 `AutomaticCacheDownload.DownloadCacheURL` 取得对应 `<exe-sha256>.zip`，再把 DLL 请求键与 `cached_offsets.txt` / `cached_bitfields.cache` 交叉核对。
- 若新头文件声明了缓存中不存在的函数，改用语义等价且缓存中真实存在的官方入口，重新编译并上服测试。

### 死亡事件中的状态字段不是静态快照

编译成功、offset 能命中，只能证明字段可访问，不能证明事件触发时字段仍保留业务所需语义。尤其在 `AShooterGameMode.Killed`、`Die`、销毁和掉落生成链路中，Actor 的当前队伍、拥有者或状态可能已经被游戏修改。

- 恐龙驯服判断不要仅因为旧 BitField 被移除，就机械替换成单个 `TargetingTeamField()`；未命名家养生物的 `TamedName` 也可能为空。
- 若官方文档和当前缓存允许，可把当前/上一/原始队伍、`OwningPlayerIDField()`、`TamedAtTimeField()`、`TamedNameField()` 等作为候选信号，但应集中封装，避免业务代码到处直接读底层字段。
- 队伍阈值和字段组合属于游戏状态判断，不应仅凭字段名写成跨版本绝对规则。至少在目标服务器用同一种普通武器依次击杀一只野生生物和一只未命名家养生物，确认只有野生击杀写入事件或推进任务。
- 如果结果仍不对，给该判断加带唯一前缀、受 Debug 开关控制的定向日志，只记录目标类名和上述少量状态；确认有效信号后移除临时日志，不要长期在每次击杀时刷屏。

## 无 crash 的无响应或断联

如果服务器进程还在但客户端超时：

- 给命令或事件加唯一 id 的阶段日志。
- 只在可疑调用前后打日志。
- 不要在循环里刷大量日志。
- 收集无响应前最后一条插件日志。
- 用配置开关一次只关闭一个风险功能测试。

## 服务器不在本机

明确区分“本地编译/测试通过”和“服务器实测通过”。交付包后，列出服务器侧需要检查的日志和效果，例如：

- 插件加载 Hook 已启用。
- 命令已执行到预期阶段。
- 事件 Hook 已触发。
- 属性/功能已应用。
- 已知错误日志没有再出现。

## 隔离套路

1. 先确认服务器加载的是最新 DLL，可以看时间戳或版本/启动日志。
2. 关闭一个可选功能。
3. 复测同一个动作。
4. 恢复后再关下一个嫌疑点。
5. 最后只保留稳定的最小路径。

## HTTP/JSON 外部数据解析

插件从 Web API、远程服务或本地配置以外的 JSON 获取任务、奖励、玩家信息时，要把返回内容视为不可信外部数据：

- 字符串字段可能缺失，也可能存在但值为 `null`，不要直接假设能按字符串读取。
- 数字、布尔、数组和对象字段也要检查类型；错误类型要给出可定位日志，而不是让异常直接中断整批处理。
- 建议封装 `StringOrEmpty`、`IntOrDefault`、`BoolOrDefault` 这类安全读取函数，用于任务号、玩家 id、服务器标识、蓝图路径、动作类型等字段。
- 批量处理任务时，单条任务解析失败应尽量记录 `jobNo/actionType/playerKey/eosId` 等上下文并跳过或回写失败，不要让一条脏数据影响整轮轮询。
- 如果日志出现 `json.exception.type_error`、`type must be string, but is null` 这类错误，优先检查后端返回里是否有可空字段或字段类型变化。

## GiveItem 发物品排错

使用 `AShooterPlayerController::GiveItem` 发物品时，先用目标服务器已经验证过的蓝图格式测试，优先参考同服 ArkShop、礼包插件或已有配置中的 `Blueprint` 字段。

- 不要默认短类名可用，例如 `PrimalItemResource_Stone_C` 可能找得到玩家但 `GiveItem` 返回失败。
- ASA/ArkServerApi 常见可用格式是完整蓝图路径，例如 `Blueprint'/Game/PrimalEarth/CoreBlueprints/Resources/PrimalItemResource_Stone.PrimalItemResource_Stone'`。
- 如果日志已经过了玩家查找阶段，但出现 `GiveItem failed: <blueprint>`，优先检查蓝图路径格式，而不是继续查网络、token 或在线玩家。
- 如果奖励任务从后端生成，要注意任务表里的 `payload_json` 往往是奖励配置的快照；只改奖励模板不一定会影响已经创建的待发任务。

## 日志中文编码

ASA 插件日志、控制台、PowerShell、Windows 区域设置和源码编码可能不一致。出现中文乱码时，先判断是显示/编码问题还是业务逻辑问题：

- 玩家可见文本、配置说明和后台文案可以用中文；不要用“替换成 `?` 或改成英文”来规避应该保留的中文。
- 源码里有中文字符串字面量时，MSVC 项目优先加 `/utf-8`，确保源码按 UTF-8 编译。
- 游戏内聊天、玩家名、中文命令、`FString` 和 `std::string` 互转，优先按 `api-lookup.md` 使用 UTF-8 转换，例如 `FString::FromStringUTF8()`、`ToStringUTF8()`、`TCHAR_TO_UTF8`。
- AsaApi logger 的 Windows 控制台 sink 可能走 `WriteConsoleA` / 系统 ANSI 代码页。若源码和业务字符串是 UTF-8，写 `Log::GetLog()` 前可用 `MultiByteToWideChar(CP_UTF8)` 再 `WideCharToMultiByte(CP_ACP)` 转成系统 ACP，类似 `Utf8ToAnsiForConsole()`；HTTP/数据库/JSON 回写仍保持 UTF-8，不要转 ACP。
- 区分插件自己的日志和 AsaApi core 日志。`[PluginName]` 前缀通常来自插件自己调用 `Log::GetLog()`；`[API][info] Loaded plugin ... (Description)` 这类版本加载日志由 AsaApi 读取 `PluginInfo.json` 后打印。插件日志正常不代表 `PluginInfo.json` 中文描述也会正常显示。
- 如果只有 `Loaded plugin ... (中文 Description)` 乱码，先检查 `PluginInfo.json` 是否为 UTF-8、启动控制台代码页是否为 65001，以及 AsaApi 当前 logger 是否用窄字符输出。可在服务器启动脚本前置 `chcp 65001 >nul`；也可在插件 `Plugin_Init()` 早期调用 `SetConsoleOutputCP(CP_UTF8)` / `SetConsoleCP(CP_UTF8)`，但同时要让插件自己的日志包装按当前控制台输出代码页决定是否转码，避免切到 UTF-8 后仍转 ACP 造成反向乱码。
- 控制台日志和文件日志可能共用同一个 sink 链。若控制台中文正常但文件用 UTF-8 查看乱码，需要单独评估自建 UTF-8 文件日志，而不是把 API 数据或玩家文案改成 ACP。
- 第三方插件中文乱码通常不代表本插件异常；先按日志前缀区分来源。
