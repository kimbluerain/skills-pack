---
name: hermes-webui-ops
description: "Hermes Studio Web UI 运维手册 — Profile 创建、GroupChat 调试、Issue 提交流程"
category: meta
tags: [hermes-webui, profiles, group-chat, debugging, github-issues]
---

# Hermes Web UI 运维

> 覆盖 Hermes Studio 桌面应用的常见运维场景。

## 1. Profile 创建

### 基于已有 profile 克隆创建

```bash
# 查看现有 profile（确认模型配置）
hermes profile list

# 从 researcher 克隆（使用 Xiaomi MiMo 2.5）
hermes profile create gangjing --clone-from researcher
```

### 配置三步走

**① SOUL.md** — 定义 profile 人格和行为守则（`~/.hermes/profiles/<name>/SOUL.md`）

**② config.yaml** — 模型、工作目录、display 语言：
```yaml
model:
  default: mimo-v2.5
  provider: xiaomi
terminal:
  cwd: $PROJECT_DIR/ex/<name>
agent:
  max_turns: 120
display:
  personality: concise
  language: zh
```

**③ .env** — API key 必须从全局 `.env` 复制到 profile 自己的 `.env`：
```bash
grep '^XIAOMI_API_KEY=' $HERMES_HOME/.env > $HERMES_HOME/profiles/<name>/.env
```

⚠️ Kanban worker 不会加载 profile 的 `.env`，只有 `~/.hermes/.env` 和 `config.yaml` 中的 `api_key` 字段被读取。

### 验证

```bash
hermes --profile gangjing chat -q "用一句话回应测试" --quiet
hermes profile show gangjing
```

---

## 2. GroupChat（群聊）调试

### 架构

GroupChat 代码在 `EKKOLearnAI/hermes-web-ui` 仓库，不是 `NousResearch/hermes-agent`。

关键文件：
- `packages/server/src/services/hermes/group-chat/index.ts` — 消息接收、存储、分发
- `packages/server/src/services/hermes/group-chat/agent-clients.ts` — agent 连接管理、context 构建、replyToMention
- `packages/server/src/services/hermes/group-chat/mention-routing.ts` — @提及解析和路由
- `packages/client/src/stores/hermes/group-chat.ts` — 前端消息排序、状态管理

### 数据库

SQLite 数据库：`$HERMES_WEBUI_HOME/hermes-web-ui.db`

关键表：
- `gc_rooms` — 房间配置（triggerTokens, totalTokens 等）
- `gc_room_agents` — 房间中的 agent（profile, invited）
- `gc_room_members` — 人类成员
- `gc_messages` — 所有消息
- `gc_session_profiles` — agent session 映射

### 触发机制

**群聊触发靠 @提及，不是 token 门槛！**

- 用户消息 → 扫描 `@agent名` → 路由到对应 agent
- `@all` → 触发房间所有 agent
- `triggerTokens` 字段存在但代码中未用作分发触发
- agent 回复默认不会自动 @ 其他 agent
- agent 间互 @ 有深度限制（max 4 层，由 `maxAgentMentionDepth()` 控制）

### 常见问题诊断

**问题：发消息没人回**
1. 检查 `gc_room_agents.invited` 是否为 1
2. 检查消息是否包含 `@agent名` 或 `@all`
3. 查看 server.log：`tail -f ~/.hermes-web-ui/logs/server.log | grep -i group`
4. 检查 agent bridge 进程是否运行：`ps aux | grep hermes_bridge`

**问题：消息上下跳动**
根因：`group-chat.ts` 第 287 行按 `timestamp` 排序，streaming 完成时的时间戳导致排序变化。已知 issue #1546。

**问题：agent 不互相对话**
现状不支持。需要 @提及才能触发。已知 feature request #1547。

### 日志位置

```
~/.hermes-web-ui/logs/server.log    # Node.js 服务器日志
~/.hermes-web-ui/logs/bridge.log    # Python agent bridge 日志
```

---

## 3. Issue 提交流程

### 确认仓库

- Hermes Agent 核心：`NousResearch/hermes-agent`
- Hermes Web UI（Studio）：`EKKOLearnAI/hermes-web-ui` ← 群聊相关来这里

### 提交前检查

```bash
gh auth status                          # 确认已登录
```

搜索已有 issue 避免重复：
- 用 GitHub API 或直接在 Issues 页搜索关键词
- 关注中文关键词：群聊、@提及、agent 协作

### Issue 编写要点

- **中文标题**（仓库有中文用户群）
- **附源码分析**：指出具体文件和行号
- **附数据库查询结果**：证明问题不是配置错误
- **附日志摘录**：server.log 的关键片段
- **提改进方案**：不只是报 bug，给出可操作的修复建议
- **关联已有 issue**：comment 交叉引用

### 已知 Issues

| # | 标题 | 类型 |
|---|------|------|
| 1546 | 多 agent 回复时消息按完成时间排序导致跳动 | Bug |
| 1547 | 自动回复开关 + agent 互 @ 权限 | Feature |
| 1385 | Agent 互@ + 对话追随（用户 hack） | Feature |
| 1516 | 多 agent 协作 limitation | Bug |
| 1450 | Profile 说话说一半就停下 | Bug |

---

## 参考资料

- [references/groupchat-architecture.md](references/groupchat-architecture.md) — GroupChat 详细架构分析

## ⚠️ 常见陷阱

### Hermes Studio ≠ hermes-agent 仓库

Hermes Studio 桌面应用和 hermes-agent 命令行工具是两个项目，两个仓库：

| | Hermes Agent | Hermes Studio (Web UI) |
|---|---|---|
| 仓库 | `NousResearch/hermes-agent` | `EKKOLearnAI/hermes-web-ui` |
| 形态 | CLI + Gateway | Electron 桌面应用 |
| 语言 | Python | TypeScript (Vue + Koa) |
| GroupChat | ❌ 无此功能 | ✅ 有（但不完善） |

**提 issue 时必须选对仓库。** 群聊相关问题全部去 `EKKOLearnAI/hermes-web-ui`。
