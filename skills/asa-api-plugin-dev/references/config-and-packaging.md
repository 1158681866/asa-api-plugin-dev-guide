# 配置、测试、编译、打包

源码、默认配置、文档、测试和包目录要保持一致。

## 配置

- 新字段同时加到代码默认值和发布配置。
- 数字要校验或 clamp。
- 字符串模式统一转小写。
- 高风险可选功能用明确布尔开关。
- 删除功能时，同时删除配置字段和文档说明。
- 发布包常见结构是 `config.json` 加 `config说明.json` 或 `config-commented.json`。
- `config.json` 是插件读取的严格 JSON；说明文件通常复制真实配置结构并在字段旁写说明，只给服务器管理员看。
- 说明内容应包含字段用途、默认值、倍率/概率/时间计算示例、重载命令和注意事项。

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

如果项目有测试 exe，编译后运行。

## 打包

如果有打包脚本，执行打包脚本。随后检查：

- 包目录存在。
- DLL 时间是新的。
- 包内配置是预期配置。
- `PluginInfo.json` 存在。
- 项目要求的文档已包含。

交付时给出包目录和 DLL 时间。
