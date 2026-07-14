# 配置、测试、编译、打包

源码、默认配置、说明文件、测试和包目录要保持一致。

## 配置

- 新字段同时加到代码默认值和发布配置。
- 数字要校验或 clamp。
- 字符串模式统一转小写。
- 高风险可选功能用明确布尔开关。
- 删除功能时，同时删除配置字段和文档说明。
- 区分运行配置和说明配置。运行配置给插件读取，说明配置给服务器管理员看。
- 服务器管理员经常调整的玩法、文案、倍率、概率、列表类内容优先配置化。
- 内部技术参数、临时排错参数、错误配置后风险较高的参数不默认暴露；需要暴露时写清安全范围。
- 发布包应包含根目录 `config.json` 和 `config说明.json`。
- `README.md` 可选。
- `config.json` 是插件读取的严格 JSON；`config说明.json` 负责写字段用途、默认值、倍率/概率/时间计算示例、重载命令和注意事项。
- `config说明.json` 不要写成简单 key-value 说明对象。可按项目需要选择字段表式结构或 JSONC 短注释样例；面向小白服主时优先使用接近 ArkShop 的紧凑 JSONC 排版。
- 字段表式 `config说明.json` 推荐结构：

```json
{
  "ConfigFormatVersion": 1,
  "Plugin": "PluginName",
  "说明": "本文件只用于说明 config.json 字段含义，插件运行只读取 config.json。",
  "字段": {
    "Enabled": {
      "类型": "bool",
      "默认值": true,
      "说明": "插件总开关。"
    },
    "Mode": {
      "类型": "string",
      "默认值": "Safe",
      "可选值": ["Safe", "Advanced"],
      "说明": "运行模式。"
    },
    "IntervalSeconds": {
      "类型": "int",
      "默认值": 60,
      "范围": "1 - 86400",
      "单位": "秒",
      "说明": "任务间隔。"
    }
  },
  "命令示例": [],
  "上服验证顺序": []
}
```

- 无论使用字段表还是 JSONC 短注释样例，每个公开运行配置字段都要能看懂中文含义；数字写单位/建议范围；枚举/模式写可选值和取值含义；危险开关写建议或注意。
- `config.json`、代码默认值、`config说明.json` 三者字段必须一致。新增、删除、重命名配置时必须同步更新三处。

### `config说明.json` 格式规则

- 优先按完整配置树编写紧凑 JSONC 样例：键、对象层级和公开字段顺序应与 `config.json` 一致，说明只写在同一行或紧邻行，方便服主对照修改。
- 中文说明使用正式、简明的运维语气。每项至少交代用途；数值补单位、有效范围和默认/常用值；开关补关键行为；列表补填写格式。不要只写“开启/关闭”，也不要把配置文件写成大段教程。
- 注释不重复 `Database.Host`、`Targets.Structures` 这类完整英文路径，字段层级已经表达位置；用自然中文描述字段作用即可。
- 列表、权限组和嵌套对象需要直观展示时可分行排版；示例项在 `config说明.json` 中标注“示例”，正式 `config.json` 仍遵循安全运行默认值。

### 公开 ZIP 的配置模板与脱敏

- 对外 ZIP 不得包含真实数据库凭据、Token、密钥、服务器专用地址或其他私有运行数据；若本地包目录兼作部署目录，只能在临时 staging 副本中改写公开配置。
- `YOUR_*` 只用于必须脱敏的敏感字段，例如 `YOUR_DATABASE`、`YOUR_USERNAME`、`YOUR_PASSWORD`。普通配置使用可读案例值，例如权限组 `VIP1`、`Admin`、常规数值和枚举值；不要把所有字段都套成脱敏占位符。
- 正式 `config.json` 必须保持可安全上服的默认状态。白名单/黑名单 ID、奖励名单、Webhook、权限名单等会直接改变行为的字段，不要预填假示例；应使用空数组、关闭状态或无目标。
- 需要让列表格式更直观时，在 `config说明.json` 的 JSONC 示例中分行展示，并明确标注示例。例如说明文件可展示两个示例 ID，正式 `config.json` 仍保持对应列表为空。
- 发布校验同时确认：ZIP 无真实敏感值、ZIP 配置符合公开安全模板、说明文件覆盖填写格式、本地部署文件夹配置未被打包流程覆盖。

## PluginInfo.json

- `PluginInfo.json` 必须使用 AsaApi 常见字段结构：

```json
{
  "FullName": "PluginName",
  "Description": "插件说明",
  "Version": 0.1,
  "MinApiVersion": 1.19,
  "Dependencies": []
}
```

- `Version` 必须是 JSON number，例如 `0.1`、`1.0`、`1.09`，不要写 `"0.1.0"` 这种字符串。
- `MinApiVersion` 必须是 JSON number，不能缺失或写成字符串；缺失时 AsaApi 可能在 `PluginManager::ReadPluginInfo` / `LoadAllPlugins` 阶段报 `type must be number, but is null`。
- 如果启动日志出现 `[json.exception.type_error.302] type must be number, but is string/null`，优先检查各插件包的 `PluginInfo.json` 里的 `Version` 和 `MinApiVersion`。
- `Name`、`FriendlyName`、`Authors` 这类自定义字段不要替代 `FullName`、`Version`、`MinApiVersion`；需要保留时也应同时保留 AsaApi 标准字段。
- `FullName` 是包内文件夹、DLL 和加载/卸载命令所依赖的稳定英文标识，不因公开中文包名、作者显示或版本展示而随意改名。
- 固定中文展示名的公开发行包可使用 `<中文插件名>.zip`，例如 `飞升部落清理插件.zip`；版本号和作者不写入文件名，分别由 `Version`、`RELEASE_MANIFEST.txt` 和加载日志确认。
- `Description` 使用完整介绍格式：`<展示名> <核心功能>，飞升，作者<署名>[，QQ <公开号码>]`。例如 `ICEASAJumper 玛娜无限跳 无限冲刺，飞升，作者ICEFIELD，QQ 2601946620`。AsaApi 的加载日志会自动组合为 `Loaded plugin <FullName> V<Version> (<Description>)`，不要在 `Description` 重复写版本号；QQ 仅在作者明确要求公开时写入。

## 测试

轻量 core tests 优先覆盖：

- 配置加载和默认值。
- 模式大小写归一化、数值 clamp。
- 状态管理逻辑。
- 资源路径归一化。
- 模板替换、颜色解析这类纯 helper。

## 编译

使用项目现有构建命令。Windows 常见形式：

```powershell
& "<VS>\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe" "<plugin>.sln" /p:Configuration=Release /p:Platform=x64
```

如果切换到较新的 AsaApi SDK 后，头文件编译报 `std::string_view::starts_with` 不存在、`FindScriptStruct` 附近模板 `>>` 语法错误等 C++ 标准相关错误，优先检查工程的 `<LanguageStandard>`。AsaApi 89.31/V2.00 一类新头文件可能需要 C++20，应将插件工程和测试工程从 `stdcpp17` 升到 `stdcpp20` 后重新 Release 编译；这属于编译标准兼容调整，不代表业务函数本身一定失效。

如果当前 SDK 的 `UnrealString.h` 报 `fmt/format.h` 缺失，不要随便引用机器上另一个 vcpkg 的 fmt。先检查该 SDK 自己的 `AsaApi/vcpkg_installed/<triplet>/<triplet>/include` 与 `lib`，把实际存在的 include/lib 目录加入插件工程，并在需要时链接同一套 `fmt.lib`。triplet 名称可能随 SDK/toolset 改变，必须以本地目录为准。编译后用 `dumpbin /DEPENDENTS` 确认发布 DLL 没意外增加未打包的 `fmt.dll` 或其他运行时依赖。

如果项目有测试 exe，编译后运行。

## 打包

如果有打包脚本，执行打包脚本。随后检查：

- 包目录存在。
- DLL 时间是新的。
- 包内配置是预期配置。
- `PluginInfo.json` 存在。
- `PluginInfo.json` 是合法 JSON，且 `Version`、`MinApiVersion` 都是 number。
- `config.json` 和 `config说明.json` 存在。
- 如项目包含 `README.md`，内容与当前行为一致。
- `config说明.json` 可以是合法 JSON 字段表，也可以是带 `//` 注释的 JSONC 样例；发布检查应确认它明确写着“插件不读取，真正生效的是 config.json”，并覆盖公开配置字段。
- 对外 ZIP 的检查要区分“说明示例”和“运行值”：仅敏感字段使用脱敏占位符；会生效的示例 ID/名单不得写进正式 `config.json`。
- 打包脚本处理中文文件名时优先使用 `-LiteralPath`，并显式检查 `config说明.json` 这个最终文件名；不要只看控制台乱码输出。
- 清理旧 release 目录前必须解析并校验目标路径确实位于项目自己的 release 子目录下，避免误删，同时避免旧包残留伪造出“打包成功”。

交付时给出包目录和 DLL 时间。
