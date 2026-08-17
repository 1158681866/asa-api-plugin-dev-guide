# 数据库与外部系统

本页用于直接使用 MySQL、共享任务表、机器人、Web 后端或进程间通信的 ASA 插件。

## 选择集成边界

- 先检查当前项目和成熟插件已有的数据库表、命令、本地配置或公开 API，不默认新建 HTTP 中转、sidecar 或消息队列。
- 只有既有路径明确无法满足需求，或业务要求服务化时，才增加新协议；字段、鉴权、幂等键、状态机、错误码、超时、重试和版本必须形成可验证契约。
- 连接成功、心跳或 HTTP 200 只证明传输层可达，不代表数据库任务已领取、游戏副作用已执行或远端已显示。

## Windows MySQL 构建

- 旧版 MySQL C Connector 在 `WIN32_LEAN_AND_MEAN` 下可能缺少 `SOCKET` / `my_socket`。在 `mysql/mysql.h` 前包含 `winsock2.h`，并链接 `Ws2_32.lib`；不要只依赖 `Windows.h` 间接声明。
- 写入 `VARCHAR` / `TEXT` 前按字段长度做 UTF-8 安全截断。固定字节 `std::string::substr()` 可能截断中文多字节字符，并在 `utf8mb4` 严格模式下让 INSERT/UPDATE 失败。

## 多服任务和幂等

- 多个服务器或插件进程消费同一任务表时，在副作用前用单条带状态与归属条件的 `UPDATE pending -> processing` 原子 claim；只有 affected rows 为 1 才继续。
- 完成、恢复和 stale 回收同时校验 `status`、`executor`、`server_key/owner`，避免接管后的旧进程继续回写。
- 区分“已 claim、尚未开始副作用”和“副作用已开始”。前者确认没有结果时可恢复；后者遇到崩溃、部分成功或确认失败时进入人工核对，不自动重试造成重复发奖。

## 线程和卸载

- HTTP、WebSocket、Named Pipe 等网络线程只处理协议、鉴权、心跳和有界纯数据队列，不访问 `UWorld`、Controller、背包或其他 UObject。
- 入站任务回到游戏线程后重新查询权威数据库和当前对象，再执行游戏操作。
- 卸载先停止接单、取消阻塞 I/O、join 网络线程，再释放数据库连接、队列和全局状态。

## 运维自检

数据库型插件的源码 README 或运维文档应提供可复制的 SQL/命令，至少能检查表是否创建、最近写入、任务/审计状态分布、失败计数和关键跳过原因。发布验证确认这些入口与当前 schema 一致，但 README 仍不必进入公开 ZIP。
