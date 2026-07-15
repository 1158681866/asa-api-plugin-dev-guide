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
- 涉及 Permissions/VIP 多档差异时，使用包含 `Default` 普通档的统一结构化组规则数组承载价格、冷却、额度、奖励或保护差异；不要另设一套非 VIP 默认值，也不要为每种权益分别增加 `FreeGroups`、`DiscountGroups`、`CooldownGroups` 等零散字段。
- 设计前先读取目标服务器真实 Permissions 组名和等级来源。`Default` 通常是普通用户组，`Admins` 通常是管理员组，`VIP1`、`VIP2` 等递增组名很常见；默认示例可以使用这些名称，但实际级数及 `SVIP`、`SSVIP` 等扩展组必须以目标数据为准。
- 玩家命中多组时取最高有效档，由它覆盖 `Default` 普通档。运行时优先使用 Permissions API；优先沿用已有权威等级，否则明确约定规则数组从低到高排列，只有没有确定顺序时才增加显式 `Priority`，不得依赖 API 返回顺序。
- 每条规则必须保留真实匹配字段，例如 `Group`。`Name` 只在确有展示用途时增加；不使用 `Default: true` 重复标记普通档。管理员绕过、访问资格和价格/权益分别判定；组服务不可用且继续执行可能误扣费、误发奖励或错误保护时采用拒绝操作的安全结果。
- 访问资格与分组价格虽然是两类逻辑，但不代表每个插件都必须同时暴露两套组配置。只有确实要禁止部分组使用功能时才增加 `AllowedGroups` 或同类白名单；若 `Default` 普通用户本来就能使用，直接删除访问白名单，不能让服主在白名单和价格数组里重复填写相同组名。
- `Default` 是未配置组的通用档。正式 `config.json` 默认只保留 `Default`；某个 VIP 的价格、冷却、额度或奖励确实不同才增加该组，未列出的 VIP 继承 `Default`。不要为了展示支持多 VIP 而预填一整套数值完全相同的组规则；示例放在 `config说明.json` 并明确标注“可选示例”。只有 `Default` 一档时不需要查询 Permissions。
- `build/package/<Plugin>/` 是本地测试目录，不是发放级产物；可以保留 `README.md`、`CHANGELOG.md` 副本和本地配置。
- 最终对外 ZIP 应包含根目录 DLL、`PluginInfo.json`、`config.json` 和 `config说明.json`；除此之外只加入确属运行必需的额外文件。
- `README.md`、`CHANGELOG.md` 和纯示例文件的权威版本保留在源码仓库，本地测试目录可以保留副本；只有最终对外 ZIP 默认排除它们。
- `config.json` 是插件读取的严格 JSON；`config说明.json` 只负责解释公开字段的用途、默认值、单位/范围、可选值和必要风险。可选在文件开头加一个简短“插件信息”对象，补充名称、内部标识、版本、作者、运行配置和单条重载方式，版本必须与 `PluginInfo.Version` 一致；其他安装流程、固定行为和上服验证放在源码仓库的 `README.md` 或项目文档。
- `config说明.json` 不要写成简单 key-value 说明对象。可按项目需要选择字段表式结构或 JSONC 短注释样例；面向小白服主时优先使用接近 ArkShop 的紧凑 JSONC 排版。
- JSONC 中嵌套数组或对象不能只解释容器本身；首个示例项应在 `Group`、价格、数量等字段旁给出短注释，后续重复项可只说明与上一档的差异。
- 字段表式 `config说明.json` 推荐结构：

```json
{
  "插件信息": {
    "名称": "PluginName",
    "版本": "1.0",
    "运行配置": "config.json",
    "重载方式": "PluginName.Reload"
  },
  "配置项": {
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
  }
}
```

- 无论使用字段表还是 JSONC 短注释样例，每个公开运行配置字段都要能看懂中文含义；数字写单位/建议范围；枚举/模式写可选值和取值含义；危险开关写建议或注意。
- `config说明.json` 的“配置项”对象（或 JSONC 配置树）必须覆盖 `config.json` 的全部公开字段；新增、删除、重命名配置时必须同步更新代码默认值、`config.json` 和说明文件。

### `config说明.json` 格式规则

- 优先按完整配置树编写紧凑 JSONC 样例：键、对象层级和公开字段顺序应与 `config.json` 一致，说明只写在同一行或紧邻行，方便服主对照修改。
- 中文说明使用正式、简明的运维语气。每项至少交代用途；数值补单位、有效范围、默认/常用值及特殊值的具体行为；开关补关键行为；列表补填写格式。不能为了缩短文字只写“开启/关闭”或“0 表示关闭”，也不要把配置文件写成大段教程。
- 普通数值范围用“必须大于等于 0”“必须大于 0”等完整中文表述，不在面向服主的配置说明中直接使用 `>= 0`、`> 0` 等数学符号；公式和代码示例除外。数值 `0` 有特殊含义时写清对象和结果，例如“0 表示关闭命令冷却”“0 表示该项不收费”“0 表示不限制数量”。
- 可以保留一个简短的“插件信息”对象和一条重载方式。默认在“插件信息”和“配置项说明”前各加一个简短分隔标题；用户明确说不要时才省略。仍不要添加联系方式、命令列表、固定安全规则、安装教程、上服验证和底部长注意事项。
- 样式参考只适用于用户明确指定的区域。如果用户只要求学习“插件信息”写法，必须保留原有配置项的结构、顺序、默认值和注释风格，不得在 JSONC 与字段表之间自行转换。
- 注释不重复 `Database.Host`、`Targets.Structures` 这类完整英文路径，字段层级已经表达位置；用自然中文描述字段作用即可。
- 列表、权限组和嵌套对象需要直观展示时可分行排版；示例项在 `config说明.json` 中标注“示例”，正式 `config.json` 仍遵循安全运行默认值。

### 公开 ZIP 的配置模板与脱敏

- 对外 ZIP 不得包含真实数据库凭据、Token、密钥、服务器专用地址或其他私有运行数据；若本地测试目录保留本地配置，只能在临时 staging 副本中改写公开配置。
- `YOUR_*` 只用于必须脱敏的敏感字段，例如 `YOUR_DATABASE`、`YOUR_USERNAME`、`YOUR_PASSWORD`。普通配置使用可读案例值，例如权限组 `Default`、`VIP1`、`Admins`、常规数值和枚举值；不要把所有字段都套成脱敏占位符。
- 正式 `config.json` 必须保持可安全上服的默认状态。白名单/黑名单 ID、奖励名单、Webhook、权限名单等会直接改变行为的字段，不要预填假示例；应使用空数组、关闭状态或无目标。
- 需要让列表格式更直观时，在 `config说明.json` 的 JSONC 示例中分行展示，并明确标注示例。例如说明文件可展示两个示例 ID，正式 `config.json` 仍保持对应列表为空。
- 发布校验同时确认：ZIP 无真实敏感值、ZIP 配置符合公开安全模板、说明文件覆盖填写格式、本地测试目录的配置和允许存在的开发文档副本未被打包流程覆盖或删除。

## PluginInfo.json

- `PluginInfo.json` 必须使用 AsaApi 常见字段结构：

```json
{
  "FullName": "PluginName",
  "Description": "插件说明",
  "Version": 1.0,
  "MinApiVersion": 2.0,
  "Dependencies": []
}
```

- `Version` 必须是 JSON number。新插件默认从 `1.0` 开始，不使用 `0.1` 作为默认起始版本，也不要写 `"1.0.0"` 这种字符串。
- `Version` 与 `MinApiVersion` 不是同一个概念：前者是插件版本，后者是最低 AsaApi 版本。不能因为 `MinApiVersion=2.0` 就把尚未发布的新插件直接升为 `Version=2.0`。
- 尚未正式发布且仍在同一轮开发/测试时，保持当前插件版本，不因每次重新构建、打包或配置调整自动递增版本；正式发布后再按已发布版本和变更范围决定是否升级。
- `MinApiVersion` 必须是 JSON number，不能缺失或写成字符串；缺失时 AsaApi 可能在 `PluginManager::ReadPluginInfo` / `LoadAllPlugins` 阶段报 `type must be number, but is null`。
- 如果启动日志出现 `[json.exception.type_error.302] type must be number, but is string/null`，优先检查各插件包的 `PluginInfo.json` 里的 `Version` 和 `MinApiVersion`。
- `Name`、`FriendlyName`、`Authors` 这类自定义字段不要替代 `FullName`、`Version`、`MinApiVersion`；需要保留时也应同时保留 AsaApi 标准字段。
- `FullName` 是包内文件夹、DLL 和加载/卸载命令所依赖的稳定英文标识，不因公开中文包名、作者显示或版本展示而随意改名。
- 固定中文展示名的公开发行包可使用 `<中文插件名>.zip`，例如 `飞升部落清理插件.zip`；版本号和作者不写入文件名，版本由 `Version` 和加载日志确认，ZIP/DLL SHA256 和验证结果在包外发布记录或交付说明中保留。
- `Description` 使用字段分隔格式：`<展示名> · <核心功能> · 作者：<署名>[ · QQ：<公开号码>]`。默认示例为 `PluginName · 核心功能说明 · 作者：示例作者`；只有作者明确要求公开时才追加 QQ。AsaApi 的加载日志会自动组合为 `Loaded plugin <FullName> V<Version> (<Description>)`，不要在 `Description` 重复写版本号。发布前必须确认 QQ 不与本机凭据、Token 等敏感值冲突；若冲突，应改用其他联系方式或先更换真实凭据，不能为保留联系方式而放宽泄漏检查。

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

不要在打包脚本里固定写死 `Community`、`Enterprise` 或 `BuildTools` 安装目录。优先用 Visual Studio Installer 自带的 `vswhere.exe` 查找当前机器真实的 x64 MSBuild：

```powershell
$vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
$msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\\**\\Bin\\amd64\\MSBuild.exe" |
    Select-Object -First 1
```

带中文字符串的 `.ps1` 如果会由 Windows PowerShell 5.1 的 `powershell.exe -File` 执行，应保存为 UTF-8 BOM（或明确使用兼容编码），并用 `powershell.exe` 实际跑一次打包脚本。只在 PowerShell 7 / `pwsh` 中解析通过，不能证明 Windows PowerShell 不会因无 BOM 把中文解码成乱码，甚至在引号附近触发解析错误。

如果切换到较新的 AsaApi SDK 后，头文件编译报 `std::string_view::starts_with` 不存在、`FindScriptStruct` 附近模板 `>>` 语法错误等 C++ 标准相关错误，优先检查工程的 `<LanguageStandard>`。AsaApi 89.31/V2.00 一类新头文件可能需要 C++20，应将插件工程和测试工程从 `stdcpp17` 升到 `stdcpp20` 后重新 Release 编译；这属于编译标准兼容调整，不代表业务函数本身一定失效。

如果当前 SDK 的 `UnrealString.h` 报 `fmt/format.h` 缺失，不要随便引用机器上另一个 vcpkg 的 fmt。先检查该 SDK 自己的 `AsaApi/vcpkg_installed/<triplet>/<triplet>/include` 与 `lib`，把实际存在的 include/lib 目录加入插件工程，并在需要时链接同一套 `fmt.lib`。triplet 名称可能随 SDK/toolset 改变，必须以本地目录为准。编译后用 `dumpbin /DEPENDENTS` 确认发布 DLL 没意外增加未打包的 `fmt.dll` 或其他运行时依赖。

如果项目有测试 exe，编译后运行。

## 打包

如果有打包脚本，执行打包脚本。随后分别检查本地测试目录和最终对外 ZIP：

- `build/package/<Plugin>/` 本地测试目录存在并已刷新；其中可以保留 `README.md`、`CHANGELOG.md` 副本和本地配置。
- 正式发布优先执行 `Release|x64` 重建；若只做新鲜度门禁，除源码外还要覆盖 `.sln/.vcxproj` 和参与构建的项目自定义 `.props/.targets`，任一输入较新时拒绝打包。
- 对最终 ZIP 内 DLL 执行 `dumpbin /headers`，确认 `Format: RSDS` 不含本机绝对 PDB 路径；同时扫描 ZIP staging 中的用户目录、项目根目录和 SDK 根目录片段。
- 最终 ZIP 内 DLL 时间是本次构建时间。
- 最终 ZIP 内配置是预期的公开配置。
- 最终 ZIP 内 `PluginInfo.json` 存在，且是合法 JSON，`Version`、`MinApiVersion` 都是 number。
- 最终 ZIP 内 `config.json` 和 `config说明.json` 存在。
- 源码仓库里的 `README.md` / 项目文档与当前行为一致；本地测试目录可以保留文档副本，但最终对外 ZIP 不包含这些开发者文档。
- 除标准四类文件外，ZIP 内每个额外文件都能说明明确的运行依赖；纯说明、变更记录和示例文件只从 ZIP 条目中排除。
- `config说明.json` 可以是合法 JSON 字段表，也可以是带 `//` 注释的 JSONC 样例；发布检查应允许一个简短的插件信息对象，同时拒绝装饰键和额外的通用说明块。
- 对外 ZIP 的检查要区分“说明示例”和“运行值”：仅敏感字段使用脱敏占位符；会生效的示例 ID/名单不得写进正式 `config.json`。
- 打包脚本处理中文文件名时优先使用 `-LiteralPath`，并显式检查 `config说明.json` 这个最终文件名；不要只看控制台乱码输出。
- ZIP 优先从临时 staging 或显式文件白名单生成；也可以先压缩再把开发文档副本放回本地测试目录。验证脚本应断言 ZIP 条目白名单和本地测试目录完整性，不得靠删除测试目录内容来通过检查。
- 清理旧 release 目录前必须解析并校验目标路径确实位于项目自己的 release 子目录下，避免误删，同时避免旧包残留伪造出“打包成功”。

交付时分别给出本地测试目录、最终对外 ZIP 和 DLL 时间。
