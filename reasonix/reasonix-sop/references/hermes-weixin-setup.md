# Hermes WeChat 个人微信接入

通过腾讯 iLink Bot API 将 Hermes Agent 接入个人微信。基于 Hermes Agent 内置的 Weixin 平台适配器。

## 数据流

微信 App → iLink Bot API → Hermes Gateway → Agent 处理 → 回复 → iLink → 微信 App

## 前置条件

- 已安装 Hermes Agent
- 一个可用的个人微信账号
- 能手机扫码

## 步骤

### 1. 安装依赖

```bash
pip install aiohttp cryptography
```

### 2. 配置 config.yaml

确保 `config.yaml` 中包含：

```yaml
gateway:
  platforms:
    weixin:
      enabled: true
```

扫码登录完成后需要改 DM 策略。向导会默认设为 `pairing`，必须改为 `open`：

```bash
sed -i 's/WEIXIN_DM_POLICY=pairing/WEIXIN_DM_POLICY=open/' ~/.hermes/.env
```

### 3. 扫码登录

需要用户在**自己的终端**运行（需要真实 TTY 渲染二维码）：

```bash
hermes gateway setup
```

选择 **12 — Weixin / WeChat**，终端显示二维码，手机微信扫码确认。

### 4. 启动网关

```bash
hermes gateway run            # 前台
hermes gateway start          # 后台服务
```

验证连接：

```bash
grep weixin ~/.hermes/logs/gateway.log | tail -5
# 成功: ✓ weixin connected  account=xxx@im.bot
```

## 限制

| 限制 | 说明 |
|------|------|
| **群聊不可用** | iLink Bot 通常无法接收群消息 |
| **仅私聊** | 绝大多数部署只能私聊正常收发 |
| **登录过期** | 会话可能过期（`errcode=-14`），需要重新扫码 |
| **消息分片** | 单条消息上限 4000 字符 |

## 故障排查

- `aiohttp and cryptography are required` → `pip install aiohttp cryptography`
- `WEIXIN_TOKEN is required` → 重新运行 `hermes gateway setup`
- Session expired (`errcode=-14`) → 重新扫码
- Bot 不回复私信 → 检查 `WEIXIN_DM_POLICY` 是否为 `open`
- 终端二维码不显示 → `pip install hermes-agent[messaging]` 或使用 URL 打开
