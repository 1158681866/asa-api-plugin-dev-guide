# 配置与命令

## 配置原则

- 默认值保守。
- 高风险功能可关闭。
- 玩家可见文字可改。
- 颜色、倍率、概率可配置。
- 配置读入时做校验。
- 配置错误要输出明确原因。

## 常见字段

```json
{
  "DebugLogging": false,
  "EnableCommandReply": true,
  "NotificationMode": "chat"
}
```

## 配置文件分工

推荐发布包至少提供两份配置：

```text
config.json
config-commented.json
```

`config.json` 是插件运行时读取的文件，应保持严格 JSON，不写 `//` 注释，避免解析器不兼容。

`config-commented.json`、`config说明.json` 或 `CONFIG.zh-CN.md` 是给服主看的说明文件，可以写注释、公式、示例、命令和注意事项。

这种分工有几个好处：

- 服主能直接看懂字段含义。
- 插件读取配置时不依赖“带注释 JSON”解析。
- 更新配置时可以对照说明文件，不容易填错。
- 中文服可以额外提供中文说明，英文服可以保留英文说明。

说明文件里建议写清楚：

- 每个字段的用途。
- 默认值代表什么。
- 数值倍率如何计算。
- 修改后是否需要重载或重启。
- 对应的 RCON / 控制台命令。

## 字符串模式

模式字段建议转小写：

```text
chat
server
screen
```

未知模式回退到默认值。

## 数值字段

数值字段要限制范围：

- 半径最小值
- 概率 `0.0..1.0`
- 颜色 `0.0..1.0`
- 倍率必须大于 `0`
- 数量必须大于 `0`

## 命令设计

推荐玩家命令：

```text
/plugin
/plugin <mode>
/plugin status
/plugin cancel
```

推荐管理员命令：

```text
/plugin reload
Plugin.Reload
```

RCON / 控制台重载可以减少重启服务器次数。

## 命令回执

命令回执最好可关闭：

```json
"EnableCommandReply": true
```

如果怀疑聊天命令回调重入，可以延迟发送消息，并保存玩家弱引用。
这只是排查手段，不应作为所有插件的固定写法；如果当前接口已稳定，保持简单同步回执即可。
