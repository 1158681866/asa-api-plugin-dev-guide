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

自动化脚本不要假设开发机一定安装 Visual Studio Community。使用 `vswhere.exe` 同时兼容 Community、Enterprise、Professional 和 Build Tools：

```powershell
$vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
$msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\\**\\Bin\\amd64\\MSBuild.exe" |
    Select-Object -First 1
& $msbuild ".\\plugin.sln" /p:Configuration=Release /p:Platform=x64
```

如果 `package.ps1` 含中文并由 Windows PowerShell 5.1 执行，保存为 UTF-8 BOM，并用 `powershell.exe -File .\\package.ps1` 做一次真实验证。无 BOM UTF-8 脚本可能在 `pwsh` 中正常，却在 Windows PowerShell 中出现中文乱码或字符串终止符解析错误。

切换 AsaApi SDK 分支后，如果头文件开始报 C++ 标准相关错误，例如 `std::string_view::starts_with` 不存在，或 `FindScriptStruct` 附近出现模板 `>>` 语法错误，先检查工程文件里的 `<LanguageStandard>`。较新的 AsaApi SDK 可能需要 C++20，把插件工程和测试工程从 `stdcpp17` 调整到 `stdcpp20` 后再重新编译。这个现象通常说明编译标准不够新，不等于某个业务 Hook 或字段已经失效。

### Release DLL 新鲜度与 PDB 路径

正式发布优先在打包前执行一次 `Release|x64` 的 `Rebuild`，成功后再复制本次构建输出的 DLL。若打包脚本复用已有 DLL 并只做时间新鲜度检查，输入不能只包含 `.cpp/.h`；至少还要包含 `.sln/.vcxproj` 以及实际参与本项目构建的自定义 `.props/.targets`。任一输入比 DLL 新时必须拒绝打包，避免编译标准、链接选项或依赖路径已经变化，却仍复制旧 DLL。

即使发布包不包含 `.pdb`，MSVC 生成的 DLL 仍可能在 PE CodeView/RSDS 记录中保存完整 PDB 路径。Release 链接应让该记录只保留文件名或其他非本机路径，例如使用 `/PDBALTPATH:%_PDB%`。打包后应对实际包内 DLL 执行 `dumpbin /headers` 检查 `Format: RSDS`，并扫描 ZIP staging 或解压内容中的已知用户目录、项目根目录和 SDK 根目录；出现盘符绝对路径、UNC 路径或本机路径片段时拒绝发布。

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

### 本地测试目录检查

`build/package/<Plugin>/` 是本地测试目录，不是发放级产物。打包后检查：

- 目录已刷新，DLL 时间和本地配置符合本次测试目标。
- `PluginInfo.json`、`config.json`、`config说明.json` 存在。
- `README.md`、`CHANGELOG.md` 副本可以保留；不得为了精简 ZIP 删除这些文件或源码树中的权威版本。
- 若目录保留真实本地配置，打包流程没有用公开模板或脱敏占位符覆盖它。

### 最终对外 ZIP 检查

- ZIP 已更新，且只包含 DLL、`PluginInfo.json`、`config.json`、`config说明.json` 和确属运行必需的额外文件；每个额外文件都能说明运行依赖原因。
- `README.md`、`CHANGELOG.md` 和纯开发示例未进入 ZIP。
- `config说明.json` 覆盖全部公开字段，使用正式、简明中文说明用途、单位/范围和关键行为；可选有一个简短插件信息/重载对象。默认检查插件信息和配置项说明前各有一个简短分隔标题，用户明确不要时除外；仍不应包含联系方式或长注意事项，也不重复完整英文路径。
- 对外 ZIP 仅对真实敏感字段使用 `YOUR_*` 脱敏占位符；普通配置保留可读案例值。
- 白名单/黑名单、奖励、权限名单、Webhook 等会生效的示例数据只放在 `config说明.json`，正式 `config.json` 保持空列表、关闭或无目标等安全默认值。

生成 ZIP 时优先使用临时 staging 或显式 ZIP 白名单；如果直接从本地测试目录压缩，可先生成 ZIP，再把 `README.md`、`CHANGELOG.md` 等副本放回测试目录。验证脚本应同时断言 ZIP 条目符合白名单，且本地测试目录及其配置未被精简流程破坏。

## 交付信息

- 编译结果
- 测试结果
- 包目录
- DLL 时间
- 服务器上要验证的日志或游戏内效果
