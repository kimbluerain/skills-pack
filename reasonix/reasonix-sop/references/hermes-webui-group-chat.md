# Hermes Web UI 群聊机制

> 来源：`EKKOLearnAI/hermes-web-ui` 仓库源码分析（2026-06-14）

## 仓库

- **项目**: `EKKOLearnAI/hermes-studio`（Web UI 包名为 `hermes-web-ui`，不是 `NousResearch/hermes-agent`）
- **语言**: TypeScript (Vue 3 前端 + Node.js Koa 后端) — 注意是 **Vue 3** 不是 React，用 `vue-tsc` 编译
- **项目结构**: monorepo，`packages/client/`（Vue 前端）+ `packages/server/`（Koa 后端）
- **构建命令**: `npm run dev`（前后端并行），`npm run build`（编译）
- **关键代理配置**: macOS 上通过代理 clone 需要设 `http_proxy=http://127.0.0.1:7897`，且大仓库建议 `--depth 1`
- **关键代码路径**:
  - 服务端核心: `packages/server/src/services/hermes/group-chat/index.ts`
  - Agent 客户端: `packages/server/src/services/hermes/group-chat/agent-clients.ts`
  - @提及路由: `packages/server/src/services/hermes/group-chat/mention-routing.ts`
  - 前端消息列表: `packages/client/src/components/hermes/group-chat/GroupMessageList.vue`
  - 前端状态管理: `packages/client/src/stores/hermes/group-chat.ts`

## 数据库结构

存储在 Web UI 的 SQLite 数据库 (`~/.hermes-web-ui/hermes-web-ui.db`)：

| 表 | 用途 |
|---|------|
| `gc_rooms` | 房间配置（triggerTokens, maxHistoryTokens, totalTokens 等） |
| `gc_room_agents` | 房间内的 agent（profile, name, invited） |
| `gc_room_members` | 人类成员 |
| `gc_messages` | 所有消息（含 role, tool_calls, reasoning 等） |
| `gc_session_profiles` | session 到 agent 的映射 |

## 触发机制：@提及路由（不是 token 门槛）

**关键发现**：`triggerTokens` 字段在代码中**未被用于触发分发**。分发全靠 `@agent名` 提及。

```typescript
// index.ts:1080-1095
const shouldRouteMentions = savedMsg.role === 'user' || ...
if (shouldRouteMentions) {
    this.agentClients.processMentions(roomId, { content, senderName, ... })
}
```

支持三种 @ 方式：

| 写法 | 效果 |
|------|------|
| `@panam` | 只触发 panam |
| `@gangjing` | 只触发 gangjing |
| `@all` | 触发房间内所有 invited=1 的 agent |

**没有 @ 提及 = agent 永远不回复。** 这是最常见的"群聊没人回"的原因。

## invited 字段

`gc_room_agents.invited`：
- `0` = agent 即使被 @ 也不会响应
- `1` = agent 可被 @ 触发

在 Web UI 里添加 agent 时默认 `invited=0`，需要手动设为 1（目前无 UI 入口，需直接改数据库）。

## 消息排序 bug：多 agent 回复时上下乱跳（#1546）

### 根因图解

```
Agent A 回复开始 → stream_start (timestamp=T1) → 消息出现在位置①
Agent B 回复开始 → stream_start (timestamp=T2, T2>T1) → 消息出现在位置②
Agent B 先写完   → sendMessage() 存 DB (DB获得新timestamp T3)
                  → 服务器广播 'message' 事件 → 客户端 handler (line 346)
                  → mergeFinalMessage() 用 DB 返回的 msg 覆盖现有消息
                  → 现有消息的 timestamp 被改为 T3（完成时间）
                  → sortedMessages 重算
Agent A 后写完   → sendMessage() 存 DB (DB获得新timestamp T4, T4>T3)
                  → 同上 → 消息 A 的 timestamp 改为 T4 → 跳到 B 下面
```

**核心问题**：`message` 事件 handler（group-chat.ts:346-362）调用 `mergeFinalMessage(existing, msg)` 时，`msg.timestamp` 来自 DB 中存入时的完成时间，覆盖了 `stream_start` 时记录的初始时间。`sortedMessages`（line 287）按 `timestamp` 排序，导致位置跳动。

### 关键代码

**排序**（group-chat.ts:287）：
```typescript
const sortedMessages = computed(() => 
    [...messages.value].sort((a, b) => a.timestamp - b.timestamp)
)
```

**stream_start**（agent-clients.ts:270-278）：
```typescript
emitMessageStreamStart(roomId, messageId): void {
    this.socket!.emit('message_stream_start', {
        roomId, id: messageId,
        senderId: ..., senderName: ...,
        timestamp: Date.now(),  // ✅ 开始时间
    })
}
```

**sendMessage 存 DB**（agent-clients.ts:224-235）— 不传 timestamp，服务器用 `Date.now()` 生成新时间：
```typescript
sendMessage(roomId, content, messageId, extra) {
    this.socket!.emit('message', { roomId, content, id: messageId, ...extra }, ...)
}
```

**服务器保存**（index.ts:1058）：
```typescript
timestamp: this.normalizeMessageTimestamp(data.timestamp, data.role),
```

**normalizeMessageTimestamp**（index.ts:1369-1376）— 非 user 消息没传 timestamp 时用 `Date.now()`：
```typescript
if (normalizedRole !== 'user') {
    const value = Number(timestamp)
    if (Number.isFinite(value) && value > 0) return value
}
return Date.now()
```

**客户端 'message' handler**（group-chat.ts:346-358）— 用 DB 返回的 msg 覆盖现有消息：
```typescript
socket.on('message', (msg: ChatMessage) => {
    const idx = messages.value.findIndex(m => m.id === msg.id)
    const existing = idx >= 0 ? messages.value[idx] : null
    const resolvedMsg = mergeFinalMessage(existing, msg)  // ← 这里 msg.timestamp 是 DB 完成时间
    if (idx >= 0) {
        messages.value[idx] = resolvedMsg                  // ← 覆盖，timestamp 变了
        messages.value = [...messages.value]               // ← 触发 computed 重算
    }
})
```

**saveMessageAndRefreshRoom 有 preserveExistingTimestamp 选项但没被用**（index.ts:472-490）：
```typescript
saveMessageAndRefreshRoom(msg, options = {}) {
    const existing = this.getMessage(msg.id)
    const message = existing && options.preserveExistingTimestamp
        ? { ...msg, timestamp: existing.timestamp }  // ✅ 这个能保留原始时间戳
        : msg                                         // ← 实际走的这里，用新时间戳
    this.upsertMessage(message)
}
```
调用处（index.ts:1069）：
```typescript
const saved = this.storage.saveMessageAndRefreshRoom(msg)
// 没有传 preserveExistingTimestamp: true
```

### 修复方案

在 `ChatMessage` 接口增加 `firstSeenAt` 字段：

1. `message_stream_start` 时：`msg.firstSeenAt = msg.timestamp`（开始时间）
2. `sortedMessages` 排序改为：`(a, b) => (a.firstSeenAt || a.timestamp) - (b.firstSeenAt || b.timestamp)`
3. `message` 事件和 `mergeFinalMessage` 中：永远不覆盖 `firstSeenAt`
4. 服务端改 `saveMessageAndRefreshRoom` 调用：加 `preserveExistingTimestamp: true`

### 影响
- 多 agent 群聊场景下阅读体验差，消息反复跳动
- 修复后消息位置在 stream_start 时固定，后续 delta 和 end 都不改变位置

### 已提交 Issue 和 PR
- Issue [#1546](https://github.com/EKKOLearnAI/hermes-studio/issues/1546)：报告此 bug，suzunn 回复确认并提供 `firstSeenAt` 方案
- PR [#1624](https://github.com/EKKOLearnAI/hermes-studio/pull/1624)（kimbluerain）：在 `ChatMessage` 接口加 `firstSeenAt` 字段，`message_stream_start` 时记录，`sortedMessages` 以此排序，`mergeFinalMessage` 保留现有 `firstSeenAt`
- 涉及文件：`packages/client/src/api/hermes/group-chat.ts`、`packages/client/src/stores/hermes/group-chat.ts`、`tests/client/group-chat-store-streaming.test.ts`
- 改后 15 项测试全部通过

## Agent 回复中断说话说一半（#1450）

**现象**：群聊中 profile 经常说话说一半就停了，需要频繁 @ 才能继续。新建群聊后正常，越用越容易发生。

**根因判断**（由维护者 EKKOLearnAI 确认，2026-06-11）：
- 更像是上游 Hermes Agent 或模型的问题，上游 v0.16.0 反馈 DeepSeek 模型不完整回复的情况比较严重
- 不是 Web UI 的 bug，是模型返回被截断

**Web UI 侧现有保护**（agent-clients.ts:561-588）：
- 流错误时（`lastChunk.status === 'error'`）发送错误消息并调用 `emitMessageStreamEnd`
- 无内容时尝试 `extractBridgeFinalText` 兜底
- 非空部分内容在结束时通过 `sendMessage` 保存到 DB

**已提交的改进 PR**：
- PR [#1625](https://github.com/EKKOLearnAI/hermes-studio/pull/1625)（kimbluerain）：
  - `emitMessageStreamEnd` 接受可选 `finishReason` 参数，正常传 `'stop'`，异常传 `'error'`
  - 客户端 `message_stream_end` 处理 `finishReason`，非 `'stop'` 时标记 `isIncomplete: true`
  - 内容末尾追加 `" ⚠️ [回复中断]"` 提示
  - `ChatMessage` 接口新增 `isIncomplete?: boolean`
  - 涉及文件：`packages/server/src/services/hermes/group-chat/agent-clients.ts`、`packages/client/src/stores/hermes/group-chat.ts`、`packages/client/src/api/hermes/group-chat.ts`

**改进方向**（Web UI 侧可做的）：
1. 检测 `finish_reason === 'length'`（触及 token 上限）时显示"回复不完整"标识
2. 增加"继续生成"按钮，把已生成内容作为上下文重新触发 agent
3. 流超时时保留已回复部分而非清空

## Agent 间上下文共享

**确认：agent 可以读到其他 agent 的消息。**

`agent-clients.ts` 的 `replyToMention()` 调用 `contextEngine.buildContext()` 时传入 `roomId`，返回的 `conversationHistory` 包含房间内所有消息（不区分发送者）。所以 panam 回复时能看到 gangjing 之前说的话，反之亦然。

## 故障排查清单

群聊没人回时，按顺序检查：

1. **消息里有没有 @agent名 或 @all？** → 没有就不会触发
2. **`gc_room_agents.invited` 是否为 1？** → 0 代表未邀请
3. **agent 的 gateway 是否在运行？** → `hermes profile list` 查看
4. **服务器日志** → `~/.hermes-web-ui/logs/server.log` 搜 `[AgentClients]`
5. **消息是否存入数据库** → `SELECT * FROM gc_messages WHERE roomId='...'`

## 上下文注入缺陷：Agent 误用 session_search

**现象**：Agent 在群聊中被 @ 后说"没查到上下文"，然后调用 `session_search` 搜索。

**根因**：`packages/server/src/services/hermes/context-engine/prompt.ts` 的 `buildAgentInstructions()` 注入的指令不够强硬：

```typescript
- 对话历史中包含多个人的消息，每条消息前标有发送者名字。
- 回复最新一条提及你的消息。
```

指令说"对话历史在你的消息里"，但没有明确禁止 agent 用工具去搜。弱模型（如 MiMo 2.5）的第一反应是用 `session_search` 找上下文，但 `session_search` 搜的是 Hermes 私聊历史，搜不到群聊消息。

**后果**：Agent 以为自己看不到上下文，实际上上下文已在系统提示词里。

**临时绕过**：在群聊 agent 的 SOUL.md 中写明"群聊上下文已注入，禁止用 session_search 查找"。（但这不应该是 SOUL 的责任，是群聊系统应提供的保证。）
