# Hermes Provider 配置坑点

## DeepSeek 走 OpenRouter 的问题

### 现象
`hermes` 报 401：`Provider: openrouter  Model: deepseek/deepseek-chat  Error: HTTP 401: Missing Authentication header`

即使用户有 `DEEPSEEK_API_KEY`，Hermes 的 `deepseek` provider 默认路由走的是 **OpenRouter**，而不是 DeepSeek 官方 API。

### 修复
```yaml
model:
  default: deepseek-v4-flash
  provider: deepseek
providers:
  deepseek:
    base_url: https://api.deepseek.com
```
同时确保 `.env` 中有 `DEEPSEEK_API_KEY`。

### root cause
Hermes 的 `deepseek` provider 硬编码了 OpenRouter 路由。显式设置 `providers.deepseek.base_url` 可覆盖。

### 常见陷阱：终端默认走 default profile

**现象**：Web UI 正常工作（panam profile），但终端 `hermes` 报 401。  
**原因**：终端 `hermes` 使用 **default profile**（无 API Key），而 Web UI 用 **panam profile**（有 Key）。两个 profile 配置不同。  
**修复**：
1. 加 alias：`alias hermes="hermes -p panam"` 到 `~/.zshrc`
2. 或每次手动：`hermes -p panam`
3. 或给 default profile 也配上同样的 Key 和 provider

**根源**：Hermes 的 `hermes config set` 命令不带 `-p` 时会写到全局 `~/.hermes/config.yaml`，这会污染所有 profile 的模型设置。如果不小心写了错误的 provider（如 `dashscope`），**所有 profile 都会受影响**。修复方法：
- 删掉或修正 `~/.hermes/config.yaml` 中的 model 段
- 每个 profile 的模型配置应该写在自己的 `~/.hermes/profiles/<name>/config.yaml` 里
