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
└── README.md        # 源码仓库的开发者/维护文档
```

## 分层建议

- `core`：纯逻辑、配置解析、可测试服务。
- `plugin`：AsaApi Hook、命令注册、游戏对象读写。
- `tests`：不依赖服务器的纯逻辑测试。
- `config`：发布默认配置。
- `build/package/<Plugin>`：本地测试目录，可用于本机检查或测试部署，并保留开发文档副本和本地配置。

## 为什么要分 core / plugin

ASA 服务器无法轻松自动化测试。把尽可能多的逻辑放进 `core`，可以用普通 exe 测试：

- 配置解析
- 模式归一化
- 状态管理
- 资源路径转换
- 文本模板
- 数值 clamp

游戏对象、Hook 和 native call 留在 `plugin` 层。

## 本地测试目录与最终对外 ZIP

`build/package/<Plugin>/` 不是发放级产物。它可以在四个基础文件和运行依赖之外保留 `README.md`、`CHANGELOG.md` 副本及本地配置：

```text
build/package/PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
├── README.md          # 可选的本地测试副本
└── CHANGELOG.md       # 可选的本地测试副本
```

只有最终对外 ZIP 属于发放级产物。ZIP 解压后应该是服务器可直接复制的结构：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config.json
├── config说明.json
└── <运行必需的额外文件>  # 仅在插件确实依赖时加入
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

这种结构对服务器管理员更直观，也方便直接复制到 `ArkApi/Plugins/PluginName/`。最终对外 ZIP 只包含 DLL、`PluginInfo.json`、`config.json`、`config说明.json`，以及确属运行必需的额外文件：

- 插件实际读取的位置必须和包内文件一致。
- `PluginInfo.json` 必须在插件根目录。
- `config.json` 应该是干净、可被严格 JSON 解析的运行配置。
- `config说明.json` 是必需的配置说明文件，通常复制一份真实配置结构后只在字段旁写必要说明；默认加简短“插件信息”对象，用 `插件加载命令`、`插件卸载命令`、`配置重载命令` 列出生命周期操作，但不在文件顶部或底部重复安装、固定规则、上服验证和长注意事项。
- 如果说明文件里有 `//` 注释，即使命名为 `.json`，也不是严格 JSON。
- `.dll.arkapi`、附属运行库、签名、校验或数据文件只有在插件运行确实需要时才加入，并在源码仓库的 README 或项目文档里说明用途。
- `README.md`、`CHANGELOG.md`、额外配置示例等仅供开发者阅读的文件可以保留在源码树和本地测试目录，默认不进入最终对外 ZIP。

如果插件还需要其他运行配置或数据文件，只有在代码会实际读取、缺少后会影响加载或功能时才放进包；纯说明、示例和开发记录仍留在源码仓库。

打包脚本优先使用临时 ZIP staging 或显式 ZIP 白名单；也可以先压缩四文件白名单，再把文档副本放回本地测试目录。不得为了精简 ZIP 删除本地测试目录或源码里的文档，也不得覆盖本地测试配置。

每次打包后检查 DLL 时间，避免服务器误拷旧包。
