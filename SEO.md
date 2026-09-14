# 官网 SEO

官网标准域名为 `https://www.cooco.me`。首页标准地址使用 `/`；其他公开页面使用不带查询参数的 `.html` 地址。

## 已实现

- 每页独立标题、描述、canonical 和 Open Graph 地址。
- 主要 15 页进入 `docs/sitemap.xml`；兼容入口 `start.html` 使用 `noindex, follow`。
- 首页 Organization 和 WebSite JSON-LD，不添加虚构评分、用户数量或产品价格。
- `docs/robots.txt` 排除插件运行目录、安装脚本与下载文件；官网安装指南 `install.html` 可抓取。robots 仅约束遵守规则的爬虫，不用于访问控制，也不保证已收录页面立即消失。
- 内部 HTML 链接不加版本参数；CSS/JS 缓存版本号由发布脚本更新。
- `coco-suite/scripts/publish-plugins.mjs` 直接复制本仓官网和 SEO 文件，不再用旧模板覆盖页面。

## 验证

在本仓运行 `python scripts/check-seo.py`。

在 coco-suite 运行 `node scripts/check-website-build.mjs`，分别验证域名根目录和 `/coco` 挂载后的真实官网打包函数。完整包仍需先完成插件构建。

## 服务器上线后

1. 上传官网及 `robots.txt`、`sitemap.xml`，刷新 HTML 缓存。HTML 建议协商缓存；带版本号的样式和脚本可长期缓存。
2. 检查首页、robots 和 sitemap 返回 200；404 页面应返回真正的 404 状态，避免全部兜底到首页。
3. 在服务器配置 HTTP 到 HTTPS、非 www 到 www，以及 `/index.html` 到 `/` 的永久跳转。保留路径，避免影响 `chat.cooco.me`、插件接口和下载地址。当前仓库没有服务器配置，尚未执行这些跳转。
4. 使用站点所有者账号配置 Google Search Console、Bing Webmaster Tools 和百度搜索资源平台，验证域名并提交站点地图。未取得账户验证信息前，不放置虚构验证码。
5. 上线后观察收录、搜索词、展示和点击；当前未承诺或验证搜索排名提升。

已上线文件及站长平台提交结果需要单独核验。本轮仅修改源码和验证打包输出，没有发布到生产服务器。
