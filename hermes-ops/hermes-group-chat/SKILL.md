---
name: hermes-group-chat
description: "设置和调试 Hermes Web UI 群聊（多 agent 辩论房间）——数据库结构、常见问题、修复方法"
category: devops
tags: [hermes, webui, group-chat, multi-agent, sqlite]
---

# Hermes Web UI 群聊 — 设置与调试

Hermes Web UI 的群聊功能允许多个 profile（agent）和用户在同一个房间里对话。常见场景：$PROFILE_NAME + gangjing 在"圆桌"里对 用户 的决策进行辩论。

## 工作原理

1. **用户发消息** → 进入对话历史
2. **Token 累计** → 当总 token 数达到 `triggerTokens` 门槛
3. **系统唤醒** → 所有 `invited=1` 的 agent 被自动邀请回复
4. **Agent 各自回复** — 每个 agent 用自己的 SOUL.md/profile 角色风格回应

## 数据库位置

```
$HERMES_WEBUI_HOME/hermes-web-ui.db  （SQLite）
```

## 核心表结构

### gc_rooms（群聊房间）
| 字段 | 说明 |
|------|------|
| `id` | 房间 ID |
| `name` | 房间名称 |
| `triggerTokens` | 触发 agent 回复的 token 门槛（默认 100000，太高！） |
| `maxHistoryTokens` | 最大历史 token 数 |

### gc_room_agents（房间里的 agent）
| 字段 | 说明 |
|------|------|
| `profile` | Hermes profile 名（$PROFILE_NAME, gangjing 等） |
| `invited` | **0 = 未邀请，不会回复；1 = 已邀请，会自动回复** |

### gc_room_members（房间里的用户）
| 字段 | 说明 |
|------|------|
| `userId` | 用户 ID（auth:1 = 管理员） |
| `userName` | 显示名称 |

### gc_session_profiles（agent 的会话映射）
| 字段 | 说明 |
|------|------|
| `session_id` | Hermes session ID |
| `room_id` | 所属房间 |
| `profile_name` | profile 名 |

### gc_messages（所有消息记录）
| 字段 | 说明 |
|------|------|
| `id` | 消息 ID |
| `senderId` | 发送者 ID |
| `senderName` | 显示名称 |
| `content` | 消息内容 |
| `timestamp` | 毫秒 Unix 时间戳 |
| `role` | user / agent |

## 常见问题

### 问题 1：群里发消息没人回

**根因排查（按顺序）：**

```sql
-- ① 检查 agent 是否被邀请
SELECT profile, invited FROM gc_room_agents WHERE roomId='<房间ID>';

-- ② 检查触发门槛
SELECT triggerTokens FROM gc_rooms WHERE id='<房间ID>';
```

**修复：**

```sql
-- 邀请所有 agent
UPDATE gc_room_agents SET invited=1 WHERE roomId='<房间ID>';

-- 降低触发门槛（2000 token ≈ 3000 字中文，约 1-2 轮对话）
UPDATE gc_rooms SET triggerTokens=2000 WHERE id='<房间ID>';
```

### 问题 2：不知道房间 ID

```sql
SELECT id, name FROM gc_rooms;
```

### 问题 3：想确认 agent 是否有活跃 session

```sql
SELECT * FROM gc_session_profiles WHERE room_id='<房间ID>';
```

### 问题 4：确认 agent 是否在线（连上了房间）

```bash
# 查看 agent 连接日志
grep "AgentClients.*joined room" ~/.hermes-web-ui/logs/server.log | tail -10
# 输出示例: [AgentClients] $PROFILE_NAME joined room: mqdd04gx8w6fj3
```

如果 agent 没有 `joined room` 的日志，说明 WebSocket 没连上，检查 profile 的 gateway 或重启 Web UI。

### 问题 5：查看消息记录

```sql
SELECT senderName, datetime(timestamp/1000,'unixepoch','localtime'), role,
       substr(replace(content, X'0A', ' '), 1, 80)
FROM gc_messages WHERE roomId='<房间ID>' ORDER BY timestamp DESC LIMIT 10;
```

## Pitfalls

- **`invited=0` 是默认值** — 新建 agent 到房间后不会自动设为 1，必须手动 UPDATE
- **`triggerTokens=100000` 太离谱** — 这相当于 30-50 页中文对话才会触发，正常聊天永远达不到
- **🔴 旧消息不会回溯触发！** — 改了 invited 或 triggerTokens 之后，agent 不会回复改之前已经存在的消息。必须在 Web UI 里**重新发一条新消息**，agent 才会被唤醒响应。这是本次会话踩过的最大的坑。
- **agent 的 profile gateway 不需要单独启动** — Web UI 通过 WebSocket 自己连接 agent，不需要手动 `gangjing gateway start`
- **改动后建议刷新 Web UI 页面** — SQL 改完后可能不需要重启服务，但刷新页面更保险

## 快速诊断脚本

运行 `references/diagnose-room.sh` 一键检查所有群聊状态：

```bash
bash ~/.hermes/profiles/$PROFILE_NAME/skills/devops/hermes-group-chat/references/diagnose-room.sh
```

输出包含：房间列表、agent 邀请状态、成员、session 映射。
