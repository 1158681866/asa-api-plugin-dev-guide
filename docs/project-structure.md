# 项目结构

推荐源码结构：

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
├── config说明.json
└── README.md        # 可选
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

## 发布包目录

包目录应该是服务器可直接复制的结构：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
├── README.md        # 可选
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

这种结构对服务器管理员更直观，也方便直接复制到 `ArkApi/Plugins/PluginName/`。当前标准要求 `config说明.json` 作为配置说明文件；是否额外使用 `README.md` 或 `config/` 子目录由项目自己决定，重点是发布包要自洽：

- 插件实际读取的位置必须和包内文件一致。
- `PluginInfo.json` 必须在插件根目录。
- `config.json` 应该是干净、可被严格 JSON 解析的运行配置。
- `config说明.json` 是必需的配置说明文件，通常复制一份真实配置结构后只在字段旁写必要说明；不在文件顶部或底部重复安装、命令、固定规则和上服验证内容。
- 如果说明文件里有 `//` 注释，即使命名为 `.json`，也不是严格 JSON。
- 如果包含 `.dll.arkapi`、签名、校验或兼容文件，应在 `README.md` 或项目文档里说明用途。

如果插件配置较复杂，也可以采用：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
├── config-commented.json  # 可选
└── README.md              # 可选
```

每次打包后检查 DLL 时间，避免服务器误拷旧包。
