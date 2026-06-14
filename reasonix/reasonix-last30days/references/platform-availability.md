# 各平台可用性现状（2026年6月记录）

当前各平台的匿名访问可行性：

| 平台 | 方式 | 可用状态 | 备注 |
|------|------|---------|------|
| Hacker News | Algolia API | ✅ 完全可用 | 无频率限制，无需任何配置 |
| YouTube | yt-dlp | ✅ 完全可用 | macOS 已安装 |
| GitHub API | curl | ✅ 完全可用 | 无认证也可搜索 |
| Polymarket | CLOB API | ✅ 可用 | 需确认具体 endpoint |
| Reddit | JSON API | ⚠️ 间歇性超时 | 设 max-time 8s，超时就跳过 |
| X (Twitter) | Nitter | ❌ 已全部关闭 | 不再可用 |
| X (Twitter) | 直接登录 | ❌ 需要登录 | 无可用 cookie/session |
| X (Twitter) | Google site: | ⚠️ 效果有限 | 只能搜到标题，看不到互动数据 |
| Google 搜索 | curl | ⚠️ 易被检测 | 会出 captcha / sorry 页面 |
| DuckDuckGo | HTML endpoint | ✅ 可用 | curl -s "https://html.duckduckgo.com/html/?q=..." |
| TikTok | scraper | ❌ 需 API key | 需配置 SCRAPECREATORS_API_KEY |
| Instagram | scraper | ❌ 需 API key | 同 TikTok |
