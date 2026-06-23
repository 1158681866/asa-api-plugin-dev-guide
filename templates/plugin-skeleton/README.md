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
├── package.ps1
└── README.md
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
README.md
```

如果提供带注释配置，请明确它只给人阅读，插件运行时读取 `config.json`。
