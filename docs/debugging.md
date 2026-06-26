# 排错手册

## Crash 有调用栈

收集：

- `crashcallstack.txt`
- 最新 `ArkApi_*.log`
- 同时间段游戏日志
- 插件 DLL 时间
- 插件配置
- ASA 服务端版本
- AsaApi 版本

看栈位置：

- 插件加载阶段：Hook 签名 / offset / SDK 版本
- 命令阶段：参数解析、权限判断、目标对象、回执发送
- Timer 阶段：重试条件、弱引用、对象失效
- 事件 Hook 阶段：字段读写、事件链、其他插件交互
- 资源阶段：类加载、库存、容器、资产路径

## 无 crash 的无响应

无 crash 的无响应需要靠阶段日志缩小范围：

```text
命令#15 阶段=收到命令
命令#15 阶段=权限检查前
命令#15 阶段=权限检查后
命令#15 阶段=保存选择前
命令#15 阶段=保存选择后
```

无响应后优先查看最后一条插件阶段日志，再结合 ArkApi 日志和服务器进程状态判断卡在哪个阶段。

## 隔离变量

不要同时改多个风险点。可按以下顺序临时关闭可选链路：

1. 关闭命令回执
2. 跳过可选目标解析
3. 关闭可选字段写入
4. 关闭通知
5. 关闭资源/库存相关逻辑
6. 移除可疑 native call

## 非本机服务器

如果开发机不是服务器：

- 只报告本地编译、测试、打包结果。
- 明确服务器侧要看哪些日志和游戏内效果。
- 确认 DLL 时间、配置文件时间和服务器实际加载路径。

## 判断是否加载旧包

如果日志仍出现已删除的旧文案或旧阶段名，优先怀疑服务器没有换到新 DLL。

## HTTP/JSON 外部数据解析

插件从 Web API、远程服务或本地配置以外的 JSON 获取任务、奖励、玩家信息时，把返回内容视为不可信外部数据。

常见问题：

- 字符串字段缺失。
- 字符串字段存在但值是 `null`。
- 数字、布尔、数组、对象字段类型和预期不一致。
- 单条脏任务导致整轮轮询中断。

建议做法：

- 封装 `StringOrEmpty`、`IntOrDefault`、`BoolOrDefault` 这类安全读取函数。
- 解析失败时记录任务号、玩家 id、EOS、动作类型、服务器标识等上下文。
- 批量处理时尽量跳过或回写单条失败，不要让一条坏数据影响整批任务。
- 如果日志出现 `json.exception.type_error` 或 `type must be string, but is null`，优先检查后端返回是否有可空字段或字段类型变化。

## GiveItem 发物品失败

`AShooterPlayerController::GiveItem` 能找到玩家但返回失败时，优先检查蓝图路径格式。

不建议默认使用短类名：

```text
PrimalItemResource_Stone_C
```

优先使用目标服务器同服 ArkShop、礼包插件或已有配置验证过的完整蓝图路径，例如：

```text
Blueprint'/Game/PrimalEarth/CoreBlueprints/Resources/PrimalItemResource_Stone.PrimalItemResource_Stone'
```

排查顺序：

1. 日志是否已经进入发物品阶段，而不是找不到玩家。
2. `GiveItem failed: <blueprint>` 中的 `<blueprint>` 是否为完整路径。
3. `quantity`、`quality`、`forceBlueprint` 是否符合预期。
4. 如果任务来自后端队列，确认任务表里的 `payload_json`，不要只改奖励模板。很多系统会在创建任务时保存奖励配置快照。

## 中文日志乱码

ASA 插件日志、Windows 控制台、PowerShell、源码文件编码、编译器输入编码、日志查看器编码可能不一致。中文乱码通常是显示/编码问题，不一定是业务逻辑问题。

建议：

- 玩家可见文案、配置说明、后台文档可以保留中文，不要用“替换成 `?` 或改成英文”规避应该保留的中文。
- 源码里有中文字符串字面量时，MSVC 项目优先加 `/utf-8`，确保源码按 UTF-8 编译。
- 游戏内聊天、玩家名、中文命令、`FString` 和 `std::string` 互转，优先使用 UTF-8 转换，例如 `FString::FromStringUTF8()`、`ToStringUTF8()`、`TCHAR_TO_UTF8`。
- AsaApi logger 的 Windows 控制台 sink 可能走 `WriteConsoleA` / 系统 ANSI 代码页。若源码和业务字符串是 UTF-8，写 `Log::GetLog()` 前可先用 `MultiByteToWideChar(CP_UTF8)` 转宽字符，再用 `WideCharToMultiByte(CP_ACP)` 转系统 ACP。
- HTTP、数据库、JSON 回写仍保持 UTF-8，不要因为控制台日志需要 ACP 就把业务数据转成 ACP。
- 控制台日志和文件日志可能共用同一个 sink 链。若控制台中文正常但文件用 UTF-8 查看乱码，需要单独评估自建 UTF-8 文件日志。
- 第三方插件日志乱码时，先看日志前缀区分来源，不要误判为当前插件异常。

示例：

```cpp
std::string Utf8ToAnsiForConsole(const std::string& value)
{
    const int wideSize = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.c_str(), -1, nullptr, 0);
    if (wideSize <= 0)
    {
        return value;
    }

    std::wstring wide(static_cast<size_t>(wideSize), L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.c_str(), -1, wide.data(), wideSize);

    const int ansiSize = WideCharToMultiByte(CP_ACP, 0, wide.c_str(), -1, nullptr, 0, nullptr, nullptr);
    if (ansiSize <= 0)
    {
        return value;
    }

    std::string ansi(static_cast<size_t>(ansiSize), '\0');
    WideCharToMultiByte(CP_ACP, 0, wide.c_str(), -1, ansi.data(), ansiSize, nullptr, nullptr);
    if (!ansi.empty() && ansi.back() == '\0')
    {
        ansi.pop_back();
    }

    return ansi;
}
```
