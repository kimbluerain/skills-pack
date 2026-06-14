---
name: reasonix-codegraph
description: CodeGraph MCP 使用指南 — 项目中存在 .codegraph/ 时，优先使用 CodeGraph MCP tools 进行代码探索（搜索、调用链、影响分析、上下文构建）
category: reasonix
tags: [codegraph, mcp, code-exploration]
---

# CodeGraph 使用指南

**前提**：项目根目录存在 `.codegraph/` 目录。不存在则直接 fallback 到原生工具（search_content / get_symbols / explore skill）。

## 快速判断矩阵

### 1. 查找符号定义
- **先试**: `codegraph_search <name>` → `codegraph_node <id>`（加 `--source` 拿源码）
- **fallback**: `search_content` + `get_symbols`
- **场景**: "XXX 是什么"、"XXX 在哪定义的"

### 2. 跨文件调用链追踪
- **先试**: `codegraph_callers <symbol>` / `codegraph_callees <symbol>`
- **fallback**: 多次 `search_content "fnName"` + `find_in_code` 跨文件追踪
- **场景**: "谁调用了 XXX"、"XXX 内部调用了哪些函数"

### 3. 修改影响分析
- **先试**: `codegraph_impact <symbol>`（传递分析，沿着调用图往下走）
- **fallback**: 递归 `search_content` 手动追踪依赖链
- **场景**: "改了 XXX 会影响到什么"、"这个改动风险多大"

### 4. 项目架构探索
- **先试**: `codegraph_context <task>`（自动构建上下文）→ 需要源码时用 `codegraph_explore`
- **fallback**: `explore` skill 或手动 search_content + read_file
- **场景**: "解释一下 X 模块怎么工作的"、"这个项目的认证流程是怎么设计的"

### 5. 文件结构快速浏览
- **先试**: `codegraph_files`（比 glob/list_directory 快，已跳过 gitignore）
- **fallback**: `glob` / `list_directory`
- **场景**: "这个目录下有什么"、"项目的入口文件在哪"

## 何时不用 CodeGraph

| 情况 | 原因 |
|------|------|
| `.codegraph/` 不存在 | 索引不可用 |
| 只需要读一个文件的内容 | `read_file` 更快更直接 |
| 需要正则搜索 | CodeGraph 不支持正则，用 `search_content` |
| 刚修改了文件 | 先 `codegraph sync` 再查，否则索引可能过时 |
| 查找文件名 | `search_files` 比 codegraph_files 更适合按名查找 |

## 注意事项

- `codegraph_explore` 和 `codegraph_context` 返回大量源码，只应在明确需要深层理解时调用
- `codegraph_callers` / `codegraph_impact` 等轻量工具可以直接在主 session 调用
- CodeGraph 索引不会自动包含新增文件，做完大改动后记得 `codegraph sync`
