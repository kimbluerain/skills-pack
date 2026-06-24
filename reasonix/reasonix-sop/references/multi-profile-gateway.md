# 多 Profile 网关冲突解决

当多个 profile 各自运行 gateway 时，所有 profile 会竞争同一个 Telegram/Discord bot token。

## 症状

```
ERROR gateway.run: Gateway exiting cleanly: discord: Discord bot token already in use (PID 12132)...
ERROR gateway.platforms.base: [Weixin] Weixin bot token already in use (PID 12132)...
```

## 根因

每个 profile 默认启动自己的 gateway（通过 launchd LaunchAgents）。当 `hermes gateway setup` 扫码登录微信时，凭证写入全局 `~/.hermes/.env`，但 profile 的 gateway 从 `~/.hermes/profiles/<name>/.env` 读取。

## 修复步骤

### 1. 停掉冲突 profile 的 launch agent

```bash
# 查看所有 hermes launch agents
launchctl list | grep hermes.gateway

# 停掉指定 profile 的网关（如 default）
launchctl bootout gui/$(id -u)/ai.hermes.gateway

# 停掉所有非当前 profile 的网关
for p in coder johnny researcher reviewer default; do
  launchctl bootout gui/$(id -u)/ai.hermes.gateway-$p 2>/dev/null || true
done
```

### 2. 杀掉残留进程

```bash
pkill -9 -f "hermes_cli.main.*gateway"
sleep 3
```

### 3. 拷贝微信凭证到目标 profile

微信扫码的凭证写在 `~/.hermes/.env`，如果目标 profile 不是 default，需要复制：

```bash
grep "WEIXIN" ~/.hermes/.env >> ~/.hermes/profiles/<target>/.env
```

### 4. 启动目标 profile 的网关

```bash
hermes --profile <name> gateway run --replace
```

验证连接状态：

```bash
grep "✓" ~/.hermes/profiles/<name>/logs/gateway.log | tail -5
```

预期看到：
- `✓ weixin connected`
- `✓ telegram connected`
- `✓ discord connected`

## 微信 DM 策略

扫码后默认 `WEIXIN_DM_POLICY=pairing`，需要改为 `open` 才能自动接收消息：

```bash
sed -i '' 's/WEIXIN_DM_POLICY=pairing/WEIXIN_DM_POLICY=open/' ~/.hermes/.env
sed -i '' 's/WEIXIN_DM_POLICY=pairing/WEIXIN_DM_POLICY=open/' ~/.hermes/profiles/<target>/.env
sed -i '' 's/WEIXIN_ALLOW_ALL_USERS=false/WEIXIN_ALLOW_ALL_USERS=true/' ~/.hermes/.env
```

## 相关 issue

- [跨平台会话上下文自动同步 #1673](https://github.com/EKKOLearnAI/hermes-studio/issues/1673)
