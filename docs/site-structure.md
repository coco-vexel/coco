# 官网页面职责与发布准备

## 浏览路径

首页 → 产品详情 → 对应获取入口。主导航以 Coco Office、Coco Travel 和开发者为一级入口；桌面端的 Coco Office 二级菜单直接提供产品概览、网页版、Office 插件和桌面应用，移动端在统一菜单中保持这些入口平铺可见。产品比较为辅助页面，不要求用户逐层选择。
开发者有独立路径：SDK 比较 → 各 SDK 的 API 与集成边界。

## 页面职责

- index.html：说明核心用途并带向具体任务，不承担全部产品文档。
- scenarios.html：展示虚构材料的单项复测结果重排（文字替换、单元格修改、字号调整），明确标注非产品截图或实时执行。
- products.html：比较浏览器、Office 宿主和本地工作区三种使用方式。
- web.html / plugins.html / desktop.html：各产品的工作流程与使用条件。
- word.html / excel.html：插件领域能力。
- download.html：统一获取路径与可用状态；install.html 保留安装步骤。
- start.html：兼容旧链接，直接重定向到 download.html。
- developers.html：只负责选择 Core 或 Editor，并提供 npm、GitHub 与 API 索引入口。
- core.html / editor.html：具体 API 与集成说明。
- support.html：兼容性与 FAQ。

## 上线前仍需真实材料

1. 网页版正式访问地址为 https://chat.cooco.me，已接入全站“开始对话”按钮。
2. 桌面安装包由维护者单独上传到官网 `/download/`：Windows x64 使用 `/download/Coco-Setup.exe`；macOS Apple 芯片和 Intel 芯片分别使用 `/download/Coco-Desktop-macOS-arm64.dmg`、`/download/Coco-Desktop-macOS-x64.dmg`；Debian / Ubuntu 系 Linux 的 amd64 和 arm64 分别使用 `/download/Coco-Desktop-Linux-amd64.deb`、`/download/Coco-Desktop-Linux-arm64.deb`。
3. 主案例运行证据：合成场景不可标记为真实执行。真实案例应包含脱敏输入、用户要求、实际执行记录、输出文件和验收结果。
4. SDK 正式发布状态：未验证分发前不提供假定可用的包安装命令。

保留独立产品页。全站标题使用统一无衬线字体；顶部主按钮统一为“打开网页版”，始终进入 https://chat.cooco.me。

页脚开发者入口按“开发者总览、Core SDK、浏览器编辑器、npm 包、GitHub 源码”排列。npm 与 GitHub 链接统一在新窗口打开。

## 2026-09-15 首页与网页版调整

首页收敛为产品介绍、一个任务示例、三种产品入口。网页版聚焦单文档单任务，移除重复的模拟多产品工作台。单元格修改示例依据本地复测重排，虚构项目材料，不作为真实产品截图或完整报告审校成功证明。所有官网页共用 navigation.css，避免旧主题覆盖产生不同导航。

插件页与桌面页沿用 website.css。插件页仅保留一次平台安装选择，保留 Word / Excel 独立说明；桌面页以文件夹工作区、操作步骤和系统说明组织内容。Windows、macOS 与 Linux 安装包使用上述 `/download/` 固定路径，由服务器上单独上传的文件提供，不打包进静态官网与 Office 插件更新包。

下载页集中桌面安装包、网页入口和 Office 平台安装；开发者页按集成目标进入 Core / Editor 独立说明。场景页保留 review / analysis / presentation 旧锚点以兼容既有链接，内容分别改为文字修改、表格更新和格式调整。

内容审查后：首页与场景页改用虚构材料和人工编排的报告完善、数据核对、格式整理示例，移除业务信息不完整的负责人修改案例及面向用户的复测措辞。插件/下载页补首次使用条件；开发者提供源码、文档、示例入口。单任务是交互方式，不将其描述为只能执行琐碎操作。
