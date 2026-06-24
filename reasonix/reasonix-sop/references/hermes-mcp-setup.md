# Hermes MCP 服务器接入模式

## 两种接入方式

### 1. HTTP 传输（如 Context7）

适用于第三方 SaaS 服务。

```bash
# 交互式
hermes mcp add context7 --url https://mcp.context7.com/mcp --auth header
# 提示输入 API key → 存入 .env 的 MCP_CONTEXT7_API_KEY

# 非交互式
printf "Y\nsk-your-key\nY\n" | hermes mcp add context7 --url https://mcp.context7.com/mcp --auth header
```

### 2. Stdio 传输（如 GitHub MCP Server）

适用于本地运行的 Node.js MCP 包。

```bash
# 先安装
npx -y github-mcp-server

# 添加（可能需要直接用 YAML）
# hermes mcp add 的 --args 可能解析失败
# fallback: 直接编辑 config.yaml
```

### YAML 配置格式

```yaml
mcp_servers:
  github:
    command: npx
    args: ["-y", "github-mcp-server"]
    env:
      GITHUB_TOKEN: "gho_xxx"
    enabled: true
```

## 常见坑

### `--args` 解析问题
Hermes CLI 可能把 `-y` 解析为自己的参数而非 MCP 命令的。解决：直接用 `hermes config edit` 编辑 YAML。

### Token 存储
- HTTP auth 的 token 存在 `~/.hermes/profiles/<name>/.env` 的 `MCP_<NAME>_API_KEY`
- Stdio env 的 token 直接写在 config.yaml 的 `env` 下
- **config.yaml 里的 token 不能有特殊字符，用引号包起来**

### 新会话生效
MCP 工具只在**新会话**中可用。旧会话看不到新加的 MCP 工具。
