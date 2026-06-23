# 项目结构

推荐结构：

```text
plugin-name/
├── src/
│   ├── core/
│   │   ├── config.*
│   │   └── service.*
│   ├── plugin/
│   │   └── plugin_main.cpp
│   └── third_party/
├── config/
│   └── plugin.json
├── tests/
│   └── test_main.cpp
├── build/
│   └── package/
├── PluginInfo.json
├── package.ps1
├── README.md
└── CONFIG.zh-CN.md
```

## 分层建议

- `core`：纯逻辑、配置解析、可测试服务。
- `plugin`：AsaApi Hook、命令注册、游戏对象读写。
- `tests`：不依赖服务器的纯逻辑测试。
- `config`：发布默认配置。
- `build/package`：可直接复制到服务器的产物。

## 为什么要分 core / plugin

ASA 服务器无法轻松自动化测试。把尽可能多的逻辑放进 `core`，可以用普通 exe 测试：

- 配置解析
- 模式归一化
- 状态管理
- 资源路径转换
- 文本模板
- 数值 clamp

游戏对象、Hook 和 native call 留在 `plugin` 层。

## 打包目录

包目录应该是服务器可直接复制的结构：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config.example.jsonc
├── README.md
└── CHANGELOG.md
```

很多现有 ASA API 插件会把运行配置直接放在插件根目录，例如：

```text
PluginName/
├── PluginName.dll
├── PluginName.dll.arkapi
├── PluginInfo.json
├── config.json
└── config说明.json
```

这种结构对服主更直观，也方便直接复制到 `ArkApi/Plugins/PluginName/`。是否使用 `config/` 子目录不是重点，重点是发布包要自洽：

- 插件实际读取的位置必须和包内文件一致。
- `PluginInfo.json` 必须在插件根目录。
- `config.json` 应该是干净、可被严格 JSON 解析的运行配置。
- 带注释的配置说明文件只给人看，不要作为运行配置读取；如果里面有 `//` 注释，即使命名为 `.json`，也应按 JSONC/说明文件处理。
- 如果包含 `.dll.arkapi`、签名、校验或兼容文件，要在 README 里说明用途。

如果插件配置较复杂，也可以采用：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config.example.jsonc
└── README.md
```

每次打包后检查 DLL 时间，避免服务器误拷旧包。
