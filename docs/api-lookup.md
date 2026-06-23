# API 与 Hook 查询

## 本地优先

本地 SDK 是编译真相。先搜本地，再看 wiki。

```powershell
rg -n "DECLARE_HOOK|SetHook|<FunctionName>" <sdk-or-project>
rg -n "ClientServerChatDirectMessage|SendChatMessage|SendServerMessage|SendNotification" <sdk>
rg -n "GetNativePointerField|Field\\(\\)" <sdk>
```

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
- 工程建议：需要结合插件场景和实测。
- 项目经验：不能直接写成通用标准。

详细见：[官方 API 来源与经验边界](official-api-sources.md)。

## Hook 接入规则

Hook 前必须确认：

- 原生函数完整名字
- 参数数量
- 参数类型
- 返回值
- 是否有 `_Implementation`
- 是否存在于当前 SDK/服务器版本

推荐写法：

```cpp
DECLARE_HOOK(SomeHook, ReturnType, ClassType*, Arg1Type, Arg2Type);
```

注册失败时，不要硬试。先回头查签名。

## 选 Hook 的优先级

1. 明确业务事件 Hook
2. 直接传入目标对象的 Hook
3. 生命周期 Hook
4. 短时有上限重试
5. 定时扫描
6. 高频全局 Hook

越靠后风险越高。
