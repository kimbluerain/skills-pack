# Hermes 运维小记

本文件记录 Hermes Studio / Agent 的运维技巧，按场景索引。

## Hermes Studio 更新

- 更新检查：打开 App → 菜单栏 → Hermes Studio → 检查更新（或启动时自动检测）
- 更新机制：electron-updater，CDN 地址 `https://download.ekkolearnai.com`
- **无法通过 curl 直接下载**：CDN 要求 App 特定的请求头，只能通过 App 内置更新器
- 更新配置文件：`/Applications/Hermes Studio.app/Contents/Resources/app-update.yml`
- 版本号：`defaults read /Applications/Hermes\ Studio.app/Contents/Info.plist CFBundleShortVersionString`

## 视觉模型配置

当 Hermes 报 `No LLM provider configured for task=vision`：
```bash
hermes config set auxiliary.vision.provider dashscope
hermes config set auxiliary.vision.model qwen-vl-max
hermes config set auxiliary.vision.base_url https://dashscope.aliyuncs.com/compatible-mode/v1
```
前提：`.env` 中已配置 `DASHSCOPE_API_KEY`。需 `/new` 重开生效。

## ToDesk 每次需要重装

**根因**：ToDesk 把运行数据（config.ini、日志、缓存）写入 `.app/Contents/`，破坏代码签名。

**验证**：`codesign --verify --verbose /Applications/ToDesk.app`

**临时修复**：`sudo codesign --force --deep --sign - /Applications/ToDesk.app`

## 微信/WeChat 接入

依赖安装：
```bash
pip install aiohttp cryptography
```

扫码登录：
```bash
hermes gateway setup
# 选 13 — Weixin / WeChat
# 手机扫二维码确认
```

扫码后处理：
- WEIXIN_* 变量写入全局 `~/.hermes/.env`
- 若不使用默认 profile，需**手动复制变量到 profile 级 env**（如 `~/.hermes/profiles/panam/.env`）
- DM_POLICY 默认 pairing → 改为 open
- 若启动失败报 "token already in use"，需停掉默认网关：
  ```bash
  launchctl bootout gui/$(id -u)/ai.hermes.gateway
  ```

## GitHub MCP 接入

```bash
hermes mcp add github --command npx --args -y --args github-mcp-server --env "GITHUB_TOKEN=$(gh auth token)"
```
如果 `--args` 被 hermes 解析拦截，直接写 config.yaml 的 `mcp_servers` 段。

## git push 超时

```bash
git config http.proxy http://127.0.0.1:7892
git config https.proxy http://127.0.0.1:7892
```
