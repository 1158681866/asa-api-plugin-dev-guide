# 通知与聊天

## 接口区别

### `SendChatMessage`

普通聊天消息，有发送者名，但通常不能通过接口参数自定义颜色。部分场景可以评估消息正文是否支持游戏富文本标签。

适合：

- 普通插件聊天提示
- 普通“发送者：内容”样式

### `SendServerMessage`

服务器消息，有颜色，发送者通常偏服务器样式。

适合：

- 管理员提示
- 服务器系统消息

### `SendNotification`

屏幕通知，不进入普通聊天历史。

适合：

- 屏幕中央/上方短提示
- 需要弹出感的 UI

### `ClientServerChatDirectMessage`

直发聊天消息，有发送者名，也有颜色。实际显示样式可能接近服务器直发消息，不能只看函数名判断最终 UI。

适合：

- 需要颜色参数的直发聊天
- 目标服务器实测确认样式符合预期的插件提示

## 样式验证

通知接口要按目标游戏内样式验证：

- 聊天框前缀是否是想要的发送者名。
- 是否显示成服务器消息。
- 颜色是否生效。
- 是否进入聊天历史。
- 多行或较长文本是否换行正常。
- 中文是否正常显示。

如果目标是普通插件聊天行，优先评估 `SendChatMessage`。如果目标是服务器系统消息，评估 `SendServerMessage`。如果目标是屏幕浮动提示，评估 `SendNotification`。如果使用 `ClientServerChatDirectMessage`，发布前要截图确认它在目标服务器上的实际样式。

## 服务器生成聊天与观察器兼容

在已核对的 AsaApi 2.03 源码中，默认 `MessagingManager::SendChatMessage_Impl` 会为单个接收者构造 `FPrimalChatMessage`，然后调用该接收者的 `ClientChatMessage`；`AddOnChatMessageCallback` 则由 AsaApi 对 `AShooterPlayerController::ServerSendChatMessage_Implementation` 的 Hook 调用。`AShooterGameMode::SendChatMessage(FPrimalChatMessage)` 又是独立的服务器广播入口。因此，“客户端已显示”“服务器已广播”“AsaApi 聊天观察回调已触发”是三种不同结果，不能互相代替；其他 AsaApi 版本需要重新核对对应源码。

AsaApi 2.03 默认实现还会把每个接收者自己的 EOS ID 写入 `FPrimalChatMessage.UserId`。反向 Hook `ClientChatMessage(FPrimalChatMessage)` 采集跨服、Discord 或机器人下行消息时，不能未经验证就用 `UserId` 作为发送者去重键，否则同一条消息可能按在线接收者被放大。优先使用桥明确提供的稳定发送者 ID；没有时使用规范化后的显示发送者名与正文组合，并用至少两名同服客户端验证一条下行消息只采集一次。

公开 `ICommands` 只有聊天回调注册与移除，没有脱离玩家控制器主动发布 `AddOnChatMessageCallback` 事件的通用接口。服务器生成消息需要被其他插件消费时，优先使用双方明确支持的 API、协议桥、共享入口或共同监听的服务器广播入口。没有互操作契约时，应分别验收本服显示、观察回调和目标端转发，不能只凭其中一步宣称整条链成功。

synthetic controller / PlayerState 一类虚拟发送者只能作为版本相关的兼容实验：

- UObject 只在游戏线程通过引擎生命周期创建和销毁，跨 Tick 使用弱引用，并验证换图、重载与卸载清理；不要手工构造 UObject 或伪造 `UNetConnection`。
- 生成头能编译、字符串能解析或 getter 有返回，都不能证明 `NativeCall` ABI、对象布局、登录状态和生命周期安全。先核对当前版本精确签名，每次只测试一个对象、字段、setter 或 getter，记录前后状态；异常后默认关闭并停止自动重试。
- 先审计消费方真正读取的 getter/字段，以及读取发生在同步回调还是异步任务。只需要同步读取时，可评估严格限定 controller、线程和调用作用域的读侧探针；真人对象和作用域外调用必须走 original。
- 调用玩家入站聊天链前要审计命令检查、刷屏限制以及同链观察器对连接、Pawn、平台身份、玩家存档、权限或反作弊状态的依赖。外部生成文本先经过命令前缀门禁。
- 观察器派发、本服显示和外部转发分别计数；失败分支只能保留一个显示出口，避免原始实现和显式广播重复。外部成功必须由目标端实收或明确 ACK 证明。

这是一组风险门禁，不是要求所有插件采用固定虚拟发送者配方。具体 Hook 组合、字段选择和业务回环策略应留在项目文档中。

## 聊天命令与普通聊天的边界

- 正式聊天命令使用 `AddChatCommand` 注册，不要用 `AddOnChatMessageCallback` 手工解析来代替。ASA API 2.03 及以后会在 `Plugin_Unload()` 返回后自动清理该 DLL 注册的命令和回调，卸载函数不要重复调用 `RemoveChatCommand`、`RemoveConsoleCommand` 或 `RemoveRconCommand`。
- 正式命令命中后，AsaApi 会阻止原消息进入游戏聊天广播，并让后续聊天观察回调收到 `command_executed=true`。
- 通用聊天回调适合观察、过滤或修改普通聊天。它返回 `true` 虽能阻止游戏默认广播，但所有观察回调仍会执行；其他聊天插件可能在消息未被标记为正式命令时先记录或转发。
- 动态重载命令别名时，把注销和重新注册延迟到下一 tick/timer，不要在当前聊天命令回调中直接修改命令容器。
- 上服验收要让第二名玩家确认命令文本不可见。只有发送者看见时先排除客户端本地回显；其他玩家也能看到时再排查主动重发消息的聊天插件。

## 配置建议

```json
{
  "NotificationMode": "chat",
  "ChatSenderName": "PluginName",
  "InfoColor": [0.0, 1.0, 0.0, 1.0],
  "ErrorColor": [1.0, 0.0, 0.0, 1.0]
}
```

玩家可见文字通常建议配置化，便于不同服务器调整语气和语言。通知模式、发送者名称、颜色是否暴露给配置，取决于插件定位和服主是否真的需要调整。

如果颜色是固定状态语义，例如成功、失败、警告，可以使用代码默认值并在文档说明。如果允许服主改颜色，推荐使用 `[R, G, B, A]`，范围 `0.0..1.0`，读取时 clamp。

## 发送安全

从聊天命令里发送回执时，可以按项目情况选择同步发送或延迟发送。若遇到对象生命周期、回调重入或兼容问题，再评估延迟发送：

1. 保存玩家弱引用。
2. 延迟一 tick 或一秒。
3. 发送前确认玩家对象仍有效。

这是排错和兼容策略，不是所有插件都必须采用的固定写法。

## 文本模板

玩家可见文字可以支持模板：

```json
{
  "Messages": {
    "CommandSaved": "已选择难度：{difficulty}",
    "Applied": "插件已生效：{difficulty}"
  }
}
```

未知占位符保留原样，方便以后扩展。
