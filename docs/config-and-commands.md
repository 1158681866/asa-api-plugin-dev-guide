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
