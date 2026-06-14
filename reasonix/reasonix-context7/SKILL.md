---
name: reasonix-context7
description: Context7 MCP 使用指南 — 写代码涉及第三方库时，优先用 Context7 MCP tools 查询最新文档和代码示例，避免幻觉 API
category: reasonix
tags: [context7, mcp, documentation, libraries]
---

# Context7 使用指南

**前提**：Context7 MCP 服务器已配置（`hermes mcp add context7`）。未配置则 fallback 到 web 搜索。

## 快速判断矩阵

### 1. 查库的最新 API
- **先试**: `resolve-library-id` 把库名转成 ID → `query-docs` 查具体用法
- **fallback**: web 搜索官方文档
- **场景**: "React 19 的 use() 怎么用？"、"Express v5 middleware 签名变了？"

### 2. 查代码示例
- **先试**: `query-docs` 带 `includeCodeExamples: true`
- **fallback**: web 搜索 GitHub/issues
- **场景**: "给我一个 Supabase auth 的完整示例"

### 3. 验证 API 是否存在
- **先试**: `query-docs` 精确查询函数/方法名
- **fallback**: 直接读库源码
- **场景**: "Next.js 有没有 `unstable_cache` 这个 API？"

### 4. 版本迁移指南
- **先试**: `query-docs` 查询 breaking changes / migration guide
- **fallback**: 读 CHANGELOG.md
- **场景**: "从 v4 升 v5 有哪些 breaking changes？"

## 何时不用 Context7

| 情况 | 原因 |
|------|------|
| 查自己的代码 | 用 CodeGraph（本地代码图） |
| 纯概念问题 | 用 web 搜索更快（如"什么是闭包"） |
| 小众/新库 | Context7 可能还没索引，先查 coverage |
| 已知道答案 | 直接用，别查 |
| MCP 不可用 | fallback 到 web |

## 注意事项

- Context7 查的是**最新文档**，版本号会自动跟上，不用手动指定
- 返回结果包含 source URL，需要验证时点进去看原文
- 免费 tier 有速率限制，批量查询时分批
