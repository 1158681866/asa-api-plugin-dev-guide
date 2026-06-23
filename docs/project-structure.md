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
- 选择状态
- 奖励路径转换
- 文本模板
- 数值 clamp

游戏对象、Hook 和 native call 留在 `plugin` 层。

## 打包目录

包目录应该是服务器可直接复制的结构：

```text
PluginName/
├── PluginName.dll
├── PluginInfo.json
├── config/
└── README.md
```

每次打包后检查 DLL 时间，避免服务器误拷旧包。
