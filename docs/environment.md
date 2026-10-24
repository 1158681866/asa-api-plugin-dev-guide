# 环境与 SDK

## 必备工具

- Visual Studio 2022 C++ 工具链
- Windows MSBuild x64
- Git
- AsaApi SDK
- 可选：GitHub CLI `gh`
- 可选：vcpkg

## SDK 定位

不要写死 SDK 路径。每个项目先从这些地方找：

- `.vcxproj` 的 include / lib 配置
- CMake 配置
- README 或构建脚本
- 环境变量
- 服务器管理员或项目文档提供的路径

常见搜索：

```powershell
rg -n "AsaApi|ArkServerApi|AdditionalIncludeDirectories|AdditionalLibraryDirectories" .
```

## SDK 与服务器版本

Hook 加载阶段崩溃经常来自：

- 本地 SDK 版本和服务器 AsaApi 版本不一致
- Hook 函数名不对
- Hook 参数不对
- 服务器游戏版本更新导致偏移变化

如果 crash 栈里出现：

```text
API::Offsets::GetAddress()
API::Hooks::SetHookInternal()
```

优先排查 Hook 签名、SDK 版本和服务器 API 版本。

## API 查询顺序

1. 官方文档 / ASA API Wiki；资料足够时停止查询。
2. 资料缺失、疑似过期或签名/编译不一致时，再查当前项目实际使用的 SDK。
3. 必要时查官方 GitHub 实现和成熟插件源码。
4. 论坛/Discord 讨论仅作补充线索。

编译以实际 SDK 的 C++ 声明为准，但编译通过不能证明运行时符号、参数 ABI、对象布局和游戏行为兼容。

## 更新 SDK

同时检查官方 Release、目标稳定分支与本地 commit，不仅比较 API 版本号。纯游戏头文件修正与核心/公开 ABI 变化采用不同构件策略；更新头文件不等于要替换服务器 API。

具体判断、导入库来源和重编译要求统一见权威 Skill 的 [SDK 更新判断](../skills/asa-api-plugin-dev/references/api-lookup.md#sdk-更新判断)。
