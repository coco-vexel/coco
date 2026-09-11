# Coco

Coco 是面向文档工作的智能助手与开放能力生态，提供网页版 Agent、Office 插件和本地多文档桌面应用，并提供文档 SDK 与实验性浏览器编辑器能力。不同产品处于不同阶段，具体范围以各产品说明为准。

[官网产品总览](https://coco-vexel.github.io/coco/) · [Word 插件](https://coco-vexel.github.io/coco/word.html) · [Excel 插件](https://coco-vexel.github.io/coco/excel.html) · [能力状态](https://coco-vexel.github.io/coco/support.html#status)

本仓库是 Coco 的公共入口，用于：

- 产品文档、安装说明和版本公告；
- WPS、Microsoft Word、ONLYOFFICE 插件的 Issue 与功能建议；
- 官方及社区 workflow、skill、template 资源；
- 公开兼容性信息与已知问题。

## 官网结构

首页仅介绍产品与使用入口。网页版、插件支持、桌面下载、开发者和帮助中心分别使用独立页面；Word、Excel、Core、Editor 与 OOJSON 各自提供详情页。静态页面位于 `docs/`，全站导航与页脚样式位于 `docs/site-shell.css`，产品页组件样式位于 `docs/overview.css`，品牌视觉层位于 `docs/brand-theme.css`，阅读层级与首页成果演示样式位于 `docs/readability.css`。`docs/site.js` 仅用于产品示意的文档切换与菜单交互，不调用模型或访问文件。示意内容使用合成材料，API 示例依据当前 SDK 文档编写。

## 项目组成

| 项目 | 状态 | 说明 |
|---|---|---|
| `coco` | 已建立 | 公共社区、文档、Issue、Release 与资源入口 |
| `coco-office` | 发布候选；Editor 实验性 | `core + editor + oojson`：Word、Excel、PPT 文档 API、浏览器编辑与格式转换；公开分发以发布公告为准 |
| `coco-engine` | 私有 | `agent + workflow + skeleton + typeset` 智能能力层 |
| WPS 插件 | 已接入 | Writer / Spreadsheets 插件，具体能力取决于宿主 |
| Microsoft 插件 | 已接入 | Word / Excel Office.js 加载项，具体能力取决于宿主 |
| ONLYOFFICE 插件 | 已接入 | 文档 / 电子表格，Desktop Editors 与 Document Server 插件 |
| Coco Desktop | 开发中 | 独立桌面产品，本地工作区与多文档任务 |
| 网页版 Agent | 已具备 Agent 能力 | 浏览器对话与文档工作空间，与纯编辑器演示分开演进 |

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
