# GroupChat 架构分析

> 分析日期：2026-06-14 | Hermes Studio V0.6.14 | 仓库：EKKOLearnAI/hermes-web-ui

## 数据库 Schema

### gc_rooms
```sql
CREATE TABLE gc_rooms (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    inviteCode TEXT UNIQUE,
    triggerTokens INTEGER NOT NULL DEFAULT 100000,   -- 未用于触发分发！
    maxHistoryTokens INTEGER NOT NULL DEFAULT 32000,
    tailMessageCount INTEGER NOT NULL DEFAULT 10,
    totalTokens INTEGER NOT NULL DEFAULT 0,
    sessionSeed TEXT NOT NULL DEFAULT '0'
);
```

### gc_room_agents
```sql
CREATE TABLE gc_room_agents (
    id TEXT PRIMARY KEY,
    roomId TEXT NOT NULL,
    agentId TEXT NOT NULL,
    profile TEXT NOT NULL,           -- 对应的 Hermes profile 名
    name TEXT NOT NULL,              -- 显示名称
    description TEXT DEFAULT '',
    invited INTEGER DEFAULT 0        -- 0=未激活, 1=已激活（必须为1才能连接）
);
```

### gc_room_members
```sql
CREATE TABLE gc_room_members (
    id TEXT PRIMARY KEY,
    roomId TEXT NOT NULL,
    userId TEXT NOT NULL,            -- "auth:N" 格式用于认证用户
    userName TEXT NOT NULL,
    ...
);
```

### gc_messages
```sql
CREATE TABLE gc_messages (
    id TEXT PRIMARY KEY,
    roomId TEXT NOT NULL,
    senderId TEXT NOT NULL,
    senderName TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    role TEXT DEFAULT 'user',        -- user/assistant/tool/command
    tool_call_id TEXT,
    tool_calls TEXT,
    tool_name TEXT,
    finish_reason TEXT,
    reasoning TEXT,
    reasoning_details TEXT,
    reasoning_content TEXT
);
```

### gc_session_profiles
```sql
CREATE TABLE gc_session_profiles (
    session_id TEXT PRIMARY KEY,
    room_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    profile_name TEXT NOT NULL,
    created_at INTEGER NOT NULL
);
```

---

## 消息流转

```
用户在 Web UI 发消息
        │
        ▼
server/index.ts: handleChatMessage()
        │
        ├─► storage.saveMessageAndRefreshRoom()
        │      ├─ INSERT INTO gc_messages
        │      ├─ 重新计算 totalTokens
        │      └─ UPDATE gc_rooms SET totalTokens
        │
        ├─► nsp.to(roomId).emit('message', savedMsg)   // 广播给所有客户端
        │
        └─► shouldRouteMentions? 
               │
               YES → agentClients.processMentions(roomId, msg)
                       │
                       ├─ resolveMentionTargets()  // 解析 @agent名
                       ├─ 匹配 agent → _processAgentMention()
                       └─ agent.replyToMention()
                              │
                              ├─ contextEngine.buildContext()  // 构建上下文
                              │      └─ 拉取房间历史消息（含其他 agent 回复）
                              │
                              ├─ AgentBridgeClient.run()  // 调用 agent profile
                              │
                              └─ 流式输出 → Socket.IO emit 到房间
```

---

## 关键源码位置

| 文件 | 行号/函数 | 功能 |
|------|----------|------|
| `index.ts` | `handleChatMessage()` | 接收用户消息 |
| `index.ts:287` | `sortedMessages` | **消息排序（问题点）** |
| `index.ts:1080-1095` | `shouldRouteMentions` | 判断是否触发 mention 路由 |
| `mention-routing.ts` | `resolveMentionTargets()` | @提及解析 |
| `mention-routing.ts` | `isAgentMentioned()` | 匹配 `@agent名` |
| `mention-routing.ts` | `isAllAgentsMentioned()` | 匹配 `@all` |
| `agent-clients.ts` | `replyToMention()` | agent 回复主流程 |
| `agent-clients.ts` | `processMentions()` | 批量处理提及 |
| `agent-clients.ts` | `_processAgentMention()` | 单 agent 提及处理（含队列） |

---

## 已知限制

1. **必须 @ 才能触发**：无自动回复模式
2. **agent 不会主动互 @**：agent 回复中不自动提及对方
3. **互 @ 深度限制 4 层**：由 `maxAgentMentionDepth()` 控制
4. **消息排序按完成时间**：streaming 完成后 timestamp 更新导致跳动
5. **triggerTokens 未使用**：数据库字段存在但分发逻辑不依赖它
6. **无房间级交互设置**：没有 autoReply/allowAgentMentions 等配置

---

## 诊断命令

```bash
# 查看群聊消息
sqlite3 ~/.hermes-web-ui/hermes-web-ui.db \
  "SELECT senderName, substr(content,1,80), datetime(timestamp/1000,'unixepoch','localtime'), role 
   FROM gc_messages WHERE roomId='<roomId>' ORDER BY timestamp"

# 查看房间 agent 状态
sqlite3 ~/.hermes-web-ui/hermes-web-ui.db \
  "SELECT profile, name, invited FROM gc_room_agents WHERE roomId='<roomId>'"

# 查看房间配置
sqlite3 ~/.hermes-web-ui/hermes-web-ui.db \
  "SELECT name, triggerTokens, totalTokens FROM gc_rooms WHERE id='<roomId>'"

# 实时日志
tail -f ~/.hermes-web-ui/logs/server.log | grep -i 'group\|agent\|mqdd'

# 检查 agent bridge 进程
ps aux | grep hermes_bridge
```

---

## 修复 agent 不响应

```bash
# 1. 设置 invited=1
sqlite3 ~/.hermes-web-ui/hermes-web-ui.db \
  "UPDATE gc_room_agents SET invited=1 WHERE roomId='<roomId>'"

# 2. 降低 token 门槛（虽然不用于分发，但影响其他逻辑）
sqlite3 ~/.hermes-web-ui/hermes-web-ui.db \
  "UPDATE gc_rooms SET triggerTokens=100 WHERE id='<roomId>'"

# 3. 发送新消息时必须包含 @agent名 或 @all
```
