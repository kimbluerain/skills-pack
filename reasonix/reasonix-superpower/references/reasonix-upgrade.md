# Reasonix 升级指南

## 当前状态跟踪
- 最新 stable GitHub 发布：**v1.7.0**（2026-06-13）
- npm `latest` tag：0.53.2（❗极旧，**禁止** `npm update -g reasonix`）
- npm `next` tag：1.7.0-rc.1（候选版，非 stable）
- GitHub 仓库：`esengine/DeepSeek-Reasonix`

## 安装方式（v1.7.0+ 改为独立二进制）

v1.7.0 起，Reasonix CLI 是以 **独立二进制** 发布的，不再是 npm 包。

### 下载安装

从 GitHub Releases 下载对应平台的压缩包：

| 平台 | 文件 |
|------|------|
| macOS Intel | `reasonix-darwin-amd64.tar.gz` |
| macOS ARM (M1/M2/M3/M4) | `reasonix-darwin-arm64.tar.gz` |
| Linux AMD64 | `reasonix-linux-amd64.tar.gz` |
| Linux ARM64 | `reasonix-linux-arm64.tar.gz` |
| Windows AMD64 | `reasonix-windows-amd64.zip` |
| Windows ARM64 | `reasonix-windows-arm64.zip` |

```bash
# macOS ARM 示例
curl -sL "https://api.github.com/repos/esengine/DeepSeek-Reasonix/releases/tags/v1.7.0" \
  | grep "browser_download_url.*darwin-arm64" \
  | cut -d '"' -f 4 \
  | xargs curl -L -o /tmp/reasonix.tar.gz
tar -xzf /tmp/reasonix.tar.gz -C /tmp
mv /tmp/reasonix /usr/local/bin/reasonix
chmod +x /usr/local/bin/reasonix
```

### 验证

```bash
reasonix --version
# → reasonix v1.7.0
```

## 注意

- `reasonix desktop`（GUI）是单独的 release asset（`desktop-v1.7.0`），不要和 CLI 混淆
- 旧版通过 npm 安装的 `reasonix` 需要手动卸载：`npm uninstall -g reasonix`
