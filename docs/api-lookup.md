# API 与 Hook 查询

## 本地优先

本地 SDK 是编译真相。先搜本地，再看 wiki。

```powershell
rg -n "DECLARE_HOOK|SetHook|<FunctionName>" <sdk-or-project>
rg -n "ClientServerChatDirectMessage|SendChatMessage|SendServerMessage|SendNotification" <sdk>
rg -n "GetNativePointerField|Field\\(\\)" <sdk>
rg -n "ToStringUTF8|FromStringUTF8|TCHAR_TO_UTF8|TCHAR_TO_ANSI" <sdk-or-project>
```

## FString 与中文

玩家命令、中文别名、中文配置、玩家名和游戏内提示都要确认字符串编码。

- 需要保留中文时，优先使用 UTF-8 转换，例如 `FString::ToStringUTF8()`、`FString::FromStringUTF8()` 或 `TCHAR_TO_UTF8`。
- `FString::ToString()` 在部分 SDK 封装中可能走 ANSI 转换，容易把中文变成 `?` 或导致中文命令匹配失败。
- 如果插件支持中文命令或中文显示名，测试里要覆盖中文参数、中文配置读取和游戏内显示。
- 日志能正常输出，不代表游戏内聊天、RCON、配置读取都正常；它们可能走不同转换链。
- AsaApi 控制台日志不一定走 `FString` 链路；中文日志乱码时按 [排错手册](debugging.md) 的 `Log::GetLog()` / 系统 ACP 方案处理，不要把日志修法套到游戏内聊天或 HTTP/JSON 数据上。

## Wiki

ASA API Wiki:

```text
https://arkserverapi.wiki/asa/index.html
```

用途：

- 查函数列表
- 查类成员
- 搜接口名字
- 辅助理解 generated wrapper

注意：wiki 不是最终编译依据。写代码前仍要看本地 SDK。

Wiki 是 API 索引，不是完整插件开发教程。写文档时要区分：

- API 事实：wiki / SDK 能确认。
- 工程判断：需要结合插件场景和实测。
- 项目特定结论：不能直接写成通用标准。

详细见：[API 来源与结论分级](official-api-sources.md)。

## Hook 接入规则

Hook 前需要确认并记录来源：

- 原生函数完整名字
- 参数数量
- 参数类型
- 返回值
- 是否有 `_Implementation`
- 是否存在于当前 SDK/服务器版本

常见写法：

```cpp
DECLARE_HOOK(SomeHook, ReturnType, ClassType*, Arg1Type, Arg2Type);
```

注册失败时，不要硬试。先回头查签名。

## 选 Hook 的评估顺序

1. 明确业务事件 Hook
2. 直接传入目标对象的 Hook
3. 生命周期 Hook
4. 短时有上限重试
5. 定时扫描
6. 高频全局 Hook

这个顺序不是硬标准，只是常见评估方向。越靠后通常越需要说明触发频率、范围限制、性能成本和验证方式。
