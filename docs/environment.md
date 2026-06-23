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

1. 本地 SDK 头文件
2. ASA API Wiki
3. GitHub 源码
4. 论坛/Discord 讨论

写代码以前，最终仍以本地 SDK 能否编译为准。
