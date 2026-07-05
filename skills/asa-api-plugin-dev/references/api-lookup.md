# API 查询

官方文档 / ASA API wiki 是第一查询入口和默认依据；资料足够时直接按文档实现并停止，不查 SDK、不先照抄成熟插件。本地头文件只用于解决官方未覆盖、写得不清楚、疑似过期，或已经出现签名/编译不一致的问题。

## 查询顺序

1. 先查官方文档 / ASA API wiki：`https://arkserverapi.wiki/asa/index.html`。
2. 如果官方资料已经足够支撑实现，直接按文档实现并停止查询；不要为了“保险”优先翻 SDK 字段或成熟插件源码。`文档优先` 高于 `SDK 里字段能编译`。
3. 对常见能力先在官方文档/wiki 中找 AsaApi / ArkApi 标准封装、`AsaApi::GetApiUtils()`、SDK helper 或对象公开安全函数；不要先写底层字段访问再回头找封装。
4. 官方没有、写得不清楚、疑似过期，或编译/签名对不上时，再从项目文件里找 SDK include / lib 路径。
5. 只有进入第 4 步后，才用 `rg` 搜本地 AsaApi SDK 头文件，确认当前编译版本的签名和字段。
6. 需要借鉴业务写法时，再看成熟插件源码。
7. 如果本地 SDK 和官方文档 / wiki 不一致，编译以本地 SDK 为准，并在交付说明里标出差异。

## AsaApi 标准优先

默认优先级：

1. ASA API 官方文档 / Wiki 中明确记录的 API、签名和推荐写法。
2. 文档/wiki 指向或能确认的 AsaApi / ArkApi 标准工具封装、`AsaApi::GetApiUtils()`、SDK helper、插件框架安全函数。
3. 游戏对象公开的原生安全函数，例如 `GetPlayerViewPoint()`、`GetLocation()` 这类明确函数。
4. 已有成熟插件验证过、且当前 SDK 签名一致的写法。
5. 底层字段、组件字段、私有类信息、`NativeCall`、手写偏移。

第 5 类不能作为首选。常见底层访问包括但不限于：

- `xxxField()` / `TargetingTeamField()` / `OwningPlayerIDField()` 等字段访问器。
- `ClassPrivateField()`、`RootComponentField()`、`PawnField()`。
- `GetNativePointerField(...)`。
- 直接读写 `BitFieldValue`。
- 直接读取组件 `RelativeLocation`、`RelativeRotation`、`RelativeScale3D`。
- 直接调用未确认语义的 `NativeCall(...)`。
- 直接拿 CDO / ClassDefaultObject / Outer 链做业务判断。

必须使用第 5 类时，要求：

- 先说明已查过没有可用 AsaApi/ArkApi 标准封装或公开安全函数。
- 把访问集中封装到小函数，不把字段访问散落在业务流程里。
- 做空指针、类型检查、异常保护和低噪声日志。
- 在代码注释标明“未找到更高层封装 / 待上服验证”。
- 写字段、Destroy Actor、Spawn 后归属设置这类高风险路径必须有配置开关、权限限制、回滚或测试服验证步骤。
- 交付说明里区分“已编译确认”和“仍需上服确认”。

## 常用搜索

```powershell
rg -n "DECLARE_HOOK|SetHook|FunctionName" <sdk-or-project>
rg -n "ClientServerChatDirectMessage|SendServerMessage|SendChatMessage|SendNotification" <sdk>
rg -n "GetNativePointerField|Field\\(\\)" <sdk>
rg -n "ToStringUTF8|FromStringUTF8|TCHAR_TO_UTF8|TCHAR_TO_ANSI" <sdk-or-project>
```

## 字符串编码

处理玩家输入、中文配置、玩家名、聊天消息、RCON 回复时，先确认 `FString` 与 `std::string` 的编码转换方式。

- 需要保留中文或其他非 ASCII 字符时，优先使用 SDK 中的 UTF-8 转换，例如 `FString::ToStringUTF8()`、`FString::FromStringUTF8()` 或 `TCHAR_TO_UTF8`。
- `FString::ToString()` 在部分 SDK 封装中可能走 ANSI 转换，适合纯英文标识，不适合玩家输入、中文别名、中文显示名。
- 如果命令支持中文参数，要给 core tests 或手动测试覆盖中文别名、中文玩家名、中文配置读取。
- 日志输出、游戏内聊天、配置解析可能分别需要不同编码处理；不要用“能编译”代替“游戏内显示正确”。
- AsaApi 控制台日志不一定走 `FString` 链路；中文日志乱码时按 `debugging.md` 的 `Log::GetLog()` / 系统 ACP 方案处理，不要把日志修法套到游戏内聊天或 HTTP/JSON 数据上。

## Hook 规则

- 声明 Hook 前优先用官方文档 / wiki 确认原生函数名和参数类型；官方没有时再查本地 SDK，并记录来源。
- 如果 Hook 能直接提供目标 actor / object，通常先评估是否满足需求。
- 全局脚本派发、高频事件路径这类宽泛 Hook 需要说明业务必要性、触发频率和验证方式。
- 插件加载时如果在 `Offsets::GetAddress` / `SetHookInternal` 崩溃，通常是 Hook 签名或 SDK/服务器版本不匹配。

## 字段封装

- 本地 SDK 里的 bitfield 往往返回 `BitFieldValue<bool, ...>`，不是普通 `bool`。不要直接写 `!obj->SomeFlag()` 这种表达式，编译可能报“无法应用于 BitFieldValue”。
- 需要读这类字段时，先查当前 SDK 的封装用法或同项目已有写法；如果能用更明确的对象关系替代，例如在线玩家列表、控制器指针、类名或已确认字段，优先用这些更直接的判断。
- 不要把“字段能编译”当作“运行时安全”。尤其是蓝图路径、玩家位置/朝向、RootComponent transform、ClassPrivateField、容器/休眠结构组件、Spawn 后归属设置，优先找 AsaApi 标准 helper；没有 helper 时再隔离字段访问并上服验证。

## Wiki 用法

wiki 适合发现函数和查签名，是默认第一入口；只要 wiki 信息足够，就不为了“保险”再查本地 SDK。只有编译失败、签名不一致或 wiki 缺资料时再对照本地头文件。
