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
- 打包脚本处理中文文件名时优先使用 `-LiteralPath`，并显式检查 `config说明.json` 这个最终文件名；不要只看控制台乱码输出。
- 清理旧 release 目录前必须解析并校验目标路径确实位于项目自己的 release 子目录下，避免误删，同时避免旧包残留伪造出“打包成功”。

交付时给出包目录和 DLL 时间。
