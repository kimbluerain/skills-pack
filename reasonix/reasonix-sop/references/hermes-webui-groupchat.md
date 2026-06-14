# Hermes Studio WebUI — GroupChat 功能现状

> 2026-06-14 调研结论。此功能在 Hermes 0.16.0 中为**半成品**，不可用于生产。

## 功能概览

Web UI 的群聊功能允许在一个房间里同时放置用户和多个 agent profile，
期望用户发言后所有 agent 自动响应。

## 数据库结构

```
gc_rooms          — 房间（名称、inviteCode、triggerTokens、totalTokens）
gc_room_agents    — 房间内的 agent（profile、invited、description）
gc_room_members   — 房间内的人类成员
gc_messages       — 聊天记录（senderId、role、content、timestamp）
gc_session_profiles — agent 会话与房间的映射
```

数据库路径：`~/.hermes-web-ui/hermes-web-ui.db`

## 故障诊断清单

当群聊无响应时，按以下顺序排查：

### 1. 检查 agent 是否被邀请

```sql
SELECT profile, name, invited FROM gc_room_agents WHERE roomId='<房间ID>';
```

`invited=0` → agent 不会被唤醒。改为 1：
```sql
UPDATE gc_room_agents SET invited=1 WHERE roomId='<房间ID>';
```

### 2. 检查触发门槛

```sql
SELECT id, name, triggerTokens, totalTokens FROM gc_rooms WHERE id='<房间ID>';
```

`totalTokens` 必须 ≥ `triggerTokens` 才会触发。建议设 100-500：
```sql
UPDATE gc_rooms SET triggerTokens=100 WHERE id='<房间ID>';
```

注意：`totalTokens` 只在**新消息到达时**才更新和检查，旧消息不补触发。

### 3. 检查消息是否入库

```sql
SELECT senderName, role, datetime(timestamp/1000, 'unixepoch', 'localtime') 
FROM gc_messages WHERE roomId='<房间ID>' ORDER BY timestamp;
```

如果只有 `role=user`、没有 `role=assistant` → 分发未发生。

### 4. 检查服务器日志

```bash
grep "AgentClients\|GroupChat\|mqdd" ~/.hermes-web-ui/logs/server.log | tail -20
```

关键日志：
- `[GroupChat] Socket.IO ready at /group-chat` — 服务启动 ✓
- `[AgentClients] panam joined room: xxx` — agent 已连接 ✓
- **缺少** `dispatch`/`trigger` 相关日志 → 分发引擎未工作 ✗

### 5. 检查 agent 进程

```bash
ps aux | grep hermes_bridge | grep -v grep
```

每个参与群聊的 profile 需要有对应的 `hermes_bridge.py` 进程。
如果缺少 → group chat 中该 agent 离线。

## 已知缺陷

**消息分发引擎未实现。** 服务器能：
- ✅ 创建房间、接受 agent 连接（Socket.IO）
- ✅ 存储消息到 gc_messages
- ❌ 检查 triggerTokens 并分发消息给 agent

官方文档、Changelog、GitHub Issues 均无 GroupChat 功能记录。
属于实验性/未完成特性。

## 替代方案

用 Telegram 群聊替代 Web UI 群聊：
- 每个 profile 独立运行 gateway（`hermes --profile X gateway start`）
- 将各 bot 拉入同一个 Telegram 群
- Telegram 群中的每条消息会广播给所有 bot
- 已验证可用
