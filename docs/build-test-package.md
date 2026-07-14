# 测试、编译与打包

## 本地可测内容

- 配置加载
- 配置默认值
- 字符串模式归一化
- 数值 clamp
- 状态管理
- 文本模板替换
- 资源路径转换

## 本地不可完全验证内容

- Hook 是否在服务器实际触发
- native field 是否游戏内生效
- 与其他插件是否冲突
- 长时间运行是否无响应

## MSBuild 示例

```powershell
& "<VS>\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe" ".\\plugin.sln" /p:Configuration=Release /p:Platform=x64
```

切换 AsaApi SDK 分支后，如果头文件开始报 C++ 标准相关错误，例如 `std::string_view::starts_with` 不存在，或 `FindScriptStruct` 附近出现模板 `>>` 语法错误，先检查工程文件里的 `<LanguageStandard>`。较新的 AsaApi SDK 可能需要 C++20，把插件工程和测试工程从 `stdcpp17` 调整到 `stdcpp20` 后再重新编译。这个现象通常说明编译标准不够新，不等于某个业务 Hook 或字段已经失效。

## 测试

如果有测试 exe：

```powershell
& ".\\build\\Release\\plugin_core_tests.exe"
```

## 打包

推荐提供 `package.ps1`：

```powershell
& ".\\package.ps1" -Configuration Release
```

打包后检查：

- DLL 时间
- 包内配置
- `PluginInfo.json`
- `config.json`
- `config说明.json`
- `README.md` 可选；如存在，要和当前行为一致
- zip 是否更新
- 对外 ZIP 仅对真实敏感字段使用 `YOUR_*` 脱敏占位符；普通配置保留可读案例值。
- 白名单/黑名单、奖励、权限名单、Webhook 等会生效的示例数据只放在 `config说明.json`，正式 `config.json` 保持空列表、关闭或无目标等安全默认值。
- 如本地包目录同时用于部署，确认打包只改 ZIP staging 副本，未覆盖本地实际配置。

## 交付信息

- 编译结果
- 测试结果
- 包目录
- DLL 时间
- 服务器上要验证的日志或游戏内效果
