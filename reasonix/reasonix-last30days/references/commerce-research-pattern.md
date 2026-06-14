# 浏览器自动化 + 商业调研（2026-06 义乌调研案例）

从本 session 的 AI Agent + 义乌商业调研中提炼的工具和模式。

## 核心发现

### 最关键的工具：Skyvern（21.9k⭐）

- GitHub: Skyvern-AI/skyvern
- **用途**：用 AI 控制浏览器，自动抓取电商网站数据（比价、产品信息、店铺数据）
- **安装**：`pip install "skyvern[all]"` → `skyvern quickstart` → http://localhost:8080
- **能做什么**：告诉它"去1688搜女包，把前20个的价格、销量抓下来"，它自动打开浏览器操作
- **需要**：LLM API key（DeepSeek 即可）+ Python 3.11+

### 其他相关工具

| 工具 | 用途 | 链接 |
|------|------|------|
| Accio AI（阿里巴巴） | AI 采购 Agent，250万月活 | accio.com |
| CJDropshipping | AI 选品+一件代发平台 | cjdropshipping.com |
| 义乌购 (Yiwugo) | 义乌市场线上版，500万产品 | yiwugo.com |
| AutoDS | AI 全自动店铺管理 | autods.com |

## 调研模式

当用户问"AI + 商业"类问题时的推荐流程：

1. **先确认用户有没有现货/货源**（有货 vs 没货，方案完全不同）
2. **有货 → 建议直接开卖**（拍视频、发 TikTok/小红书），不需要先搭技术系统
3. **搜索已有工具**（花时间了解别人已经做了什么，而不是从零想方案）
4. **只推荐最简单的工具**（用户不需要全自动每天爬数据，手动每周看10分钟可能就够了）

## 参考视频

- "AI Just Changed eCommerce Forever" — Jon Law，46万播放，展示3个AI采购工作流
- Accio 2.0 演示：Tech with Tas 从 idea 到找到供应商上架，全程30分钟
