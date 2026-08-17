# Agent 项目入口

本文件只是项目级自动发现适配器，不是独立规则副本。

1. 读取并遵循 [`skills/asa-api-plugin-dev/SKILL.md`](skills/asa-api-plugin-dev/SKILL.md)。
2. 所有 `references/...` 路径都以 `skills/asa-api-plugin-dev/` 为根目录解析。
3. 只加载当前任务需要的参考文件，不一次性读取全部资料。
4. 当前 Agent 没有某个示例工具时，使用具备同等能力的搜索、编辑、构建和验证工具，不跳过对应门禁。
5. 如果此文件被单独复制而 Skill bundle 不在上述路径，不要把它当作完整指南；应安装完整 `asa-api-plugin-dev` Skill，或显式提供其实际路径。

规则权威源只有 `skills/asa-api-plugin-dev/`。任何客户端的专用入口与 UI 元数据都只能作为薄适配器，不能复制并维护另一套 ASA 开发规则。
