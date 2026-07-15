# ASA API 插件骨架

这是 ASA AsaApi 插件项目骨架说明。复制该目录后，根据实际插件名替换文件名、命名空间、配置字段和打包脚本。

建议结构：

```text
plugin-name/
├── src/core
├── src/plugin
├── config
├── tests
├── PluginInfo.json
├── config.json
├── config说明.json
├── package.ps1
└── README.md        # 开发者/维护文档，不进标准公开包
```

此模板只提供目录思路，不包含可直接编译的 C++ 代码。

## 建议分层

- `src/core`：配置解析、规则匹配、状态管理、文本模板、数值计算等可测试逻辑。
- `src/plugin`：AsaApi 命令、Hook、游戏对象访问、消息发送和插件生命周期。
- `config`：发布默认配置和配置说明样板。
- `tests`：不依赖 ASA 服务器的 core tests。

## 打包目标

最终发布包应能直接复制到：

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

标准公开包默认只包含上述四类文件。只有 `.dll.arkapi`、附属运行库、签名或数据文件等确属运行必需时才额外加入。

本模板的 `README.md` 保留在源码树中供开发者和维护者阅读，打包脚本不要复制它，也不要为了精简发布包删除它。`config说明.json` 只给人阅读，插件运行时读取严格 JSON 的 `config.json`。
