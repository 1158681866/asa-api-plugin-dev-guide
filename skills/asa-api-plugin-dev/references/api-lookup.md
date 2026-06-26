# API 查询

本地头文件是第一信息源，因为它对应当前插件实际编译使用的 SDK 版本。

## 查询顺序

1. 先从项目文件里找 SDK include / lib 路径。
2. 用 `rg` 搜本地 AsaApi SDK 头文件。
3. 再查 ASA API wiki：`https://arkserverapi.wiki/asa/index.html`。
4. 如果本地 SDK 和 wiki 不一致，编译以本地 SDK 为准，并在交付说明里标出差异。

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

- 声明 Hook 前确认原生函数名和参数类型，并记录来源。
- 如果 Hook 能直接提供目标 actor / object，通常先评估是否满足需求。
- 全局脚本派发、高频事件路径这类宽泛 Hook 需要说明业务必要性、触发频率和验证方式。
- 插件加载时如果在 `Offsets::GetAddress` / `SetHookInternal` 崩溃，通常是 Hook 签名或 SDK/服务器版本不匹配。

## 字段封装

- 本地 SDK 里的 bitfield 往往返回 `BitFieldValue<bool, ...>`，不是普通 `bool`。不要直接写 `!obj->SomeFlag()` 这种表达式，编译可能报“无法应用于 BitFieldValue”。
- 需要读这类字段时，先查当前 SDK 的封装用法或同项目已有写法；如果能用更明确的对象关系替代，例如在线玩家列表、控制器指针、类名或已确认字段，优先用这些更直接的判断。

## Wiki 用法

wiki 适合发现函数和查签名，但写代码前仍要和本地头文件对照。尤其是本地生成头文件难搜、或不熟悉某类 API 时，先用 wiki 定位，再回本地确认。
