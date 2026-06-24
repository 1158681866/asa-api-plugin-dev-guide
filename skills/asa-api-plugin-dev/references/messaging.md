# 聊天与通知

根据想要的游戏内样式选择消息接口。

## 常见接口

- `SendChatMessage(player, sender_name, msg)`：普通聊天行，有发送者名，通常没有单独颜色参数。
- `SendServerMessage(player, color, msg)`：服务器/直发聊天样式，有颜色，发送者通常偏服务器消息。
- `SendNotification(player, color, scale, time, icon, msg)`：屏幕通知，不是聊天框历史里的普通消息行。
- `ClientServerChatDirectMessage(&message, color, bold, &sender)`：直发聊天行，有发送者名，也有颜色。适合插件样式的彩色聊天提示。

所有接口写代码前都要在本地 SDK 头文件里核对签名。

## 实用选择

- 想要“发送者：内容”且能改颜色：用 `ClientServerChatDirectMessage`。
- 想要普通插件聊天行且不需要颜色：用 `SendChatMessage`。
- 想要屏幕上方/中间的浮动提示：用 `SendNotification`。
- 想要服务器彩色消息：用 `SendServerMessage`。

## 安全性

如果消息从聊天命令回调里发出，可以按项目情况选择同步发送或延迟发送。若遇到对象生命周期、回调重入或兼容问题，再评估延迟一 tick 或一秒，并保存玩家弱引用。延迟发送是兼容策略，不是所有插件都需要采用的默认写法。

## 配置建议

玩家可见文字通常建议配置化，便于不同服务器调整语气和语言。颜色是否配置化取决于插件定位：如果颜色是服主会主动调整的样式，提供配置；如果只是固定状态语义，可以用代码默认值并在文档说明。

颜色配置推荐用 `[R, G, B, A]`，范围 `0.0..1.0`，读取时 clamp。文本模板可以支持简单命名占位符，未知占位符保留原样。
