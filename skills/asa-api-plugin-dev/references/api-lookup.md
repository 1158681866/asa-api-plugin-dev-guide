# API 查询

本地头文件是第一信息源，因为它对应当前插件实际编译使用的 SDK 版本。

## 查询顺序

1. 先从项目文件里找 SDK include / lib 路径。
2. 用 `rg` 搜本地 AsaApi SDK 头文件。
3. 再查 ASA API wiki：`https://arkserverapi.wiki/asa/index.html`。
4. 如果本地 SDK 和 wiki 不一致，编译以本地 SDK 为准，并把差异告诉用户。

## 常用搜索

```powershell
rg -n "DECLARE_HOOK|SetHook|FunctionName" <sdk-or-project>
rg -n "ClientServerChatDirectMessage|SendServerMessage|SendChatMessage|SendNotification" <sdk>
rg -n "GetNativePointerField|Field\\(\\)" <sdk>
```

## Hook 规则

- 声明 Hook 前必须确认原生函数名和参数类型。
- 优先选择能直接提供目标 actor / object 的 Hook。
- 除非插件功能确实需要，否则避免全局脚本派发、高频事件路径这类宽泛 Hook。
- 插件加载时如果在 `Offsets::GetAddress` / `SetHookInternal` 崩溃，通常是 Hook 签名或 SDK/服务器版本不匹配。

## Wiki 用法

wiki 适合发现函数和查签名，但写代码前仍要和本地头文件对照。尤其是本地生成头文件难搜、或不熟悉某类 API 时，先用 wiki 定位，再回本地确认。
