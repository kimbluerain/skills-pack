# Hermes Web UI 群聊机制

> 来源：`EKKOLearnAI/hermes-web-ui` 仓库源码分析（2026-06-14）

## 仓库

- **项目**: `EKKOLearnAI/hermes-web-ui`（不是 `NousResearch/hermes-agent`）
- **语言**: TypeScript (Vue 3 前端 + Node.js Koa 后端)
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

## 消息排序 bug：多 agent 回复时上下乱跳

根因在 `group-chat.ts:287`：

```typescript
const sortedMessages = computed(() => 
    [...messages.value].sort((a, b) => a.timestamp - b.timestamp)
)
```

消息按 `timestamp` 排序。当两个 agent 同时回复时，先开始的 agent 可能后完成，完成后获得更晚的 timestamp，导致已完成消息跳到最新位置。

**影响**：用户体验差，消息会上下跳动。

**修复方向**：应改为按消息首次出现时间（stream_start 的 timestamp）固定位置，而不是完成时间。

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
