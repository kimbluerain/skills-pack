# Hermes Gateway 跨 Profile 笔记

## 凭证作用域（被坑过）

`hermes gateway setup` 扫码登录的凭证，会写入 **全局** `~/.hermes/.env`，**不是** profile 级别的 `.env`。

但 profile 网关（`hermes --profile panam gateway run`）**只读 profile 级别的** `~/.hermes/profiles/<name>/.env`。

**症状：** 微信/其他平台连接失败，日志报 `XXX_TOKEN is required`，但 `.env` 明明有值。

**解决：** 把全局 `.env` 的对应行复制到 profile 的 `.env`：

```bash
grep "WEIXIN\|DISCORD\|TELEGRAM" ~/.hermes/.env >> ~/.hermes/profiles/panam/.env
```

## 多网关冲突

每个 profile 都有自己独立的 gateway（`hermes gateway install` 安装为 LaunchAgent）。多个 profile 的网关会争夺相同的 token（Discord、Telegram、WeChat）。

**症状：** 日志报 `XXX token already in use (PID xxx). Stop the other gateway first.`

**解决：** 停掉不需要的网关：

```bash
# 列出所有网关
launchctl list | grep hermes.gateway

# 停掉指定网关（如 default）
launchctl bootout gui/$(id -u)/ai.hermes.gateway

# 全杀
pkill -9 -f "hermes_cli.main.*gateway"

# 然后只启动需要的 profile
hermes --profile panam gateway run --replace
```

## 微信 iLink Bot 要点

| 步骤 | 命令 |
|------|------|
| 装依赖 | `pip install aiohttp cryptography` |
| 扫码 | `hermes gateway setup` → 选 Weixin/WeChat |
| 改 DM 策略 | `sed -i '' 's/WEIXIN_DM_POLICY=pairing/WEIXIN_DM_POLICY=open/' ~/.hermes/.env` |
| 开全部私信 | `sed -i '' 's/WEIXIN_ALLOW_ALL_USERS=false/WEIXIN_ALLOW_ALL_USERS=true/' ~/.hermes/.env` |
| 凭证复制到 profile | 见上方"凭证作用域" |

**注意：** iLink Bot 群聊大概率不可用，只有私聊。登录可能过期（`errcode=-14`）需要重新扫码。
