# ASA API 插件骨架

这是 ASA AsaApi 插件项目骨架说明。复制该目录后，根据实际插件名替换文件名、命名空间、配置字段和打包脚本。

建议结构：

```text
plugin-name/
├── src/core
├── src/plugin
├── config
├── tests
├── build/package/PluginName/  # 本地测试目录
├── PluginInfo.json
├── config.json
├── config说明.json
├── package.ps1
└── README.md        # 开发者/维护文档，可复制到本地测试目录，不进最终对外 ZIP
```

此模板只提供目录思路，不包含可直接编译的 C++ 代码。

## 建议分层

- `src/core`：配置解析、规则匹配、状态管理、文本模板、数值计算等可测试逻辑。
- `src/plugin`：AsaApi 命令、Hook、游戏对象访问、消息发送和插件生命周期。
- `config`：发布默认配置和配置说明样板。
- `tests`：不依赖 ASA 服务器的 core tests。

## 本地测试目录与打包目标

`build/package/PluginName/` 是本地测试目录，可以保留 `README.md`、`CHANGELOG.md` 副本和本地配置。最终对外 ZIP 解压后应能直接复制到：

```text
ArkApi/Plugins/PluginName/
```

包内至少包含：

```text
PluginName.dll
PluginInfo.json
config.json
config说明.json
```

最终对外 ZIP 默认只包含上述四类文件。只有 `.dll.arkapi`、附属运行库、签名或数据文件等确属运行必需时才额外加入。

本模板的 `README.md` 权威版本保留在源码树中供开发者和维护者阅读，也可以复制进本地测试目录。打包脚本应通过临时 ZIP staging、显式 ZIP 白名单，或先压缩后恢复文档副本，只让最终对外 ZIP 排除它；不得为了精简 ZIP 删除测试目录或源码文件。`config说明.json` 只给人阅读，插件运行时读取严格 JSON 的 `config.json`。
