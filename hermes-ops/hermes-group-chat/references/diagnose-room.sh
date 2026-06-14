#!/bin/bash
# 诊断 Hermes Web UI 群聊问题
# 用法: bash diagnose-room.sh

DB="/Users/kim/.hermes-web-ui/hermes-web-ui.db"
LOGDIR="/Users/kim/.hermes-web-ui/logs"

echo "=== 群聊房间列表 ==="
sqlite3 "$DB" "SELECT id, name, triggerTokens, totalTokens FROM gc_rooms;"

echo ""
echo "=== Agent 邀请状态（invited=0 不会回复）==="
sqlite3 "$DB" "SELECT r.name, a.profile, a.invited FROM gc_room_agents a JOIN gc_rooms r ON a.roomId=r.id;"

echo ""
echo "=== 房间成员 ==="
sqlite3 "$DB" "SELECT r.name, m.userName FROM gc_room_members m JOIN gc_rooms r ON m.roomId=r.id;"

echo ""
echo "=== 最近消息（最后 5 条）==="
sqlite3 "$DB" "SELECT r.name, m.senderName, datetime(m.timestamp/1000,'unixepoch','localtime'), m.role, substr(replace(m.content, X'0A',' '),1,60) FROM gc_messages m JOIN gc_rooms r ON m.roomId=r.id ORDER BY m.timestamp DESC LIMIT 5;"

echo ""
echo "=== Agent Session 映射 ==="
sqlite3 "$DB" "SELECT profile_name, room_id FROM gc_session_profiles;"

echo ""
echo "=== Agent 连接日志（最近 10 条）==="
grep "AgentClients.*joined room\|AgentClients.*disconnected" "$LOGDIR/server.log" 2>/dev/null | tail -10

echo ""
echo "检查完毕。"
echo "  invited=0 → agent 不会回复，改: UPDATE gc_room_agents SET invited=1 WHERE roomId='<room_id>';"
echo "  triggerTokens 太高 → 正常聊天攒不到，改: UPDATE gc_rooms SET triggerTokens=2000 WHERE id='<room_id>';"
echo "  🔴 改完数据库必须重新发一条消息！旧消息不会回溯触发！"
