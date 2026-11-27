# Agent 工具包与平台资源

这里记录 Coco 在各个平台提供的 Agent 工具包、技能及相关资源。新资源、版本变更和下架通过本仓库的 Pull Request 记录。更新条目时保留已有 ID，按实际分发平台填写版本与获取入口。

## 归档目录

| 资源类型 | 目录 |
| --- | --- |
| Coco Agent 应用包 | [`coco-agent/apps/`](coco-agent/apps/README.md) |
| WorkBuddy 技能 | [`workbuddy/skills/`](workbuddy/skills/README.md) |

原始包放进对应目录的 `<资源 ID>/<版本>/`，保留文件名和扩展名。版本取自包内清单，每次发新版时新建版本目录，并在同一个 Pull Request 更新总表中的版本和归档链接。

## Coco Agent 应用包

以下为 2026-11-27 核对的 [Coco 应用市场](https://www.cooco.me/marketplace.html)在架应用。版本号链接到仓库中的同版本原始归档。应用包也可通过 Coco 产品内的应用入口登录安装。

| 应用 | 工具包 ID | 文档类型 | 在架版本与归档 |
| --- | --- | --- | --- |
| [公文排版](https://www.cooco.me/toolkits/coco.word.official-document.html) | `coco.word.official-document` | Word | [0.3.0](coco-agent/apps/coco.word.official-document/0.3.0/word-official-document-0.3.0.coco-tool) |
| [超大字打印](https://www.cooco.me/toolkits/coco.word.large-print.html) | `coco.word.large-print` | Word | [1.0.4](coco-agent/apps/coco.word.large-print/1.0.4/coco.word.large-print-1.0.4.coco-tool) |
| [标签字段对齐](https://www.cooco.me/toolkits/coco.word.labeled-fields-align.html) | `coco.word.labeled-fields-align` | Word | [1.0.7](coco-agent/apps/coco.word.labeled-fields-align/1.0.7/coco.word.labeled-fields-align-1.0.7.zip) |
| [校对](https://www.cooco.me/toolkits/coco.word.proofread.html) | `coco.word.proofread` | Word | [1.0.1](coco-agent/apps/coco.word.proofread/1.0.1/coco.word.proofread-1.0.1.zip) |
| [翻译](https://www.cooco.me/toolkits/coco.word.translate.html) | `coco.word.translate` | Word | [1.0.1](coco-agent/apps/coco.word.translate/1.0.1/coco.word.translate-1.0.1.zip) |
| [润色](https://www.cooco.me/toolkits/coco.word.polish.html) | `coco.word.polish` | Word | [1.0.1](coco-agent/apps/coco.word.polish/1.0.1/coco.word.polish-1.0.1.zip) |
| [续写](https://www.cooco.me/toolkits/coco.word.continue.html) | `coco.word.continue` | Word | [1.0.1](coco-agent/apps/coco.word.continue/1.0.1/coco.word.continue-1.0.1.zip) |
| [编号校审](https://www.cooco.me/toolkits/coco.word.numbering-audit.html) | `coco.word.numbering-audit` | Word | [1.0.1](coco-agent/apps/coco.word.numbering-audit/1.0.1/coco.word.numbering-audit-1.0.1.zip) |
| [文档清理](https://www.cooco.me/toolkits/coco.word.doc-cleanup.html) | `coco.word.doc-cleanup` | Word | [1.0.1](coco-agent/apps/coco.word.doc-cleanup/1.0.1/coco.word.doc-cleanup-1.0.1.zip) |
| [书签清理](https://www.cooco.me/toolkits/coco.word.bookmark-cleanup.html) | `coco.word.bookmark-cleanup` | Word | [1.0.1](coco-agent/apps/coco.word.bookmark-cleanup/1.0.1/coco.word.bookmark-cleanup-1.0.1.zip) |
| [生成描红字帖](https://www.cooco.me/toolkits/coco.chinese-copybook.html) | `coco.chinese-copybook` | Excel | [0.4.4](coco-agent/apps/coco.chinese-copybook/0.4.4/chinese-copybook-0.4.4.zip) |

## WorkBuddy 技能

| 技能 | 包内 ID | 对应 Coco 应用包 | 技能包归档 | 市场入口 |
| --- | --- | --- | --- | --- |
| Coco 描红字帖 | `coco-copybook-local` | `coco.chinese-copybook` | [0.2.1](workbuddy/skills/coco-copybook-local/0.2.1/coco-copybook-local-0.2.1.zip) | 待核实 |
| Coco 超大字打印 | `coco-large-print-local` | `coco.word.large-print` | [0.2.1](workbuddy/skills/coco-large-print-local/0.2.1/coco-large-print-local-0.2.1.zip) | 待核实 |

## 新资源登记

WorkBuddy 专家归入 `workbuddy/experts/`，千问办公资源归入 `qwen-office/<资源类型>/`。有首个资源时建立对应目录，并在总表记录平台资源 ID、版本或发布日期、官方获取入口和对应的 Coco 应用包 ID（如有）。
