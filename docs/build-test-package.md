# 测试、编译与打包

## 本地可测内容

- 配置加载
- 配置默认值
- 字符串模式归一化
- 数值 clamp
- 状态管理
- 文本模板替换
- 资源路径转换

## 本地不可完全验证内容

- Hook 是否在服务器实际触发
- native field 是否游戏内生效
- 与其他插件是否冲突
- 长时间运行是否无响应

## MSBuild 示例

```powershell
& "<VS>\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe" ".\\plugin.sln" /p:Configuration=Release /p:Platform=x64
```

## 测试

如果有测试 exe：

```powershell
& ".\\build\\Release\\plugin_core_tests.exe"
```

## 打包

推荐提供 `package.ps1`：

```powershell
& ".\\package.ps1" -Configuration Release
```

打包后检查：

- DLL 时间
- 包内配置
- `PluginInfo.json`
- `config.json`
- `config说明.json`
- `README.md` 可选；如存在，要和当前行为一致
- zip 是否更新

## 交付信息

- 编译结果
- 测试结果
- 包目录
- DLL 时间
- 服务器上要验证的日志或游戏内效果
