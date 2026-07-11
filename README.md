# Coco

Coco 是面向文档工作的智能助手与开放能力生态，目标是在 WPS、Microsoft Word 和 ONLYOFFICE 中提供一致的文档理解、编辑、工作流与技能体验。

本仓库是 Coco 的公共入口，用于：

- 产品文档、安装说明和版本公告；
- WPS、Microsoft Word、ONLYOFFICE 插件的 Issue 与功能建议；
- 官方及社区 workflow、skill、template 资源；
- 公开兼容性信息与已知问题。

## 项目组成

| 项目 | 状态 | 说明 |
|---|---|---|
| `coco` | 已建立 | 公共社区、文档、Issue、Release 与资源入口 |
| `coco-office` | 筹备中 | 与宿主无关的 OOXML 文档 SDK |
| `coco-oojson` | 筹备中 | OOJSON 与 OOXML / Flat OPC 转换 |
| WPS 插件 | 开发中 | WPS Writer 宿主插件 |
| Microsoft 插件 | 开发中 | Microsoft Word Office.js 加载项 |
| ONLYOFFICE 插件 | 开发中 | ONLYOFFICE 桌面与 Web 插件 |

## 反馈问题

请使用 [Issues](https://github.com/coco-vexel/coco/issues) 提交问题。提交 Bug 时请提供：

- 使用的宿主和版本；
- Coco 插件版本；
- 操作系统；
- 可复现步骤和实际结果；
- 脱敏后的日志或示例文档（如适用）。

请勿在公开 Issue 中上传包含个人信息、客户数据、密钥或访问令牌的内容。安全问题请参阅 [SECURITY.md](SECURITY.md)。

## 资源目录

```text
workflows/   文档工作流
skills/      Agent 技能
templates/   文档与排版模板
schemas/     公共资源格式定义
docs/        安装、使用和维护文档
```

资源协议和自动更新机制仍在设计中。在签名、完整性校验和能力授权机制完成前，本仓库不会分发可静默执行的第三方代码资源。

## 参与贡献

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。当前优先接收问题复现、文档改进和不包含可执行代码的资源示例。

## 许可证

许可证正在确认中。在仓库加入明确的 LICENSE 文件前，请勿假定仓库内容已获得任何开源许可。
