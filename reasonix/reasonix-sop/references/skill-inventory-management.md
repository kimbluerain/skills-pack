# Skill 盘点与归属识别

## 问题

`hermes skills list` 的 Source 列（builtin/local/official）**不可靠**——profile 创建时会把全局 skill 克隆到本地目录，导致大量本来是内置的 skill 也标为 `local`。

## 正确方法

### 1. 时间戳区分法

```bash
# Hermes 安装当天的 skill → 内置（5月27日）
find ~/.hermes/skills -name "SKILL.md" -newermt "2026-05-26" ! -newermt "2026-05-28"

# 安装日期之后的 → 后期手动装的
find ~/.hermes/skills -name "SKILL.md" -newermt "2026-06-11"
```

### 2. 目录对比法

```bash
# 全局目录（~/.hermes/skills/）= 所有 profile 共享的内置 skill
# Profile 目录（~/.hermes/profiles/<name>/skills/）= profile 专属副本

# 只在 profile 目录有的 = 用户手动加的
comm -13 \
  <(find ~/.hermes/skills -name "SKILL.md" | sort) \
  <(find ~/.hermes/profiles/panam/skills -name "SKILL.md" | sort)
```

### 3. Python 包检查

```bash
# 真正的"出厂内置"在 Python 包里
find /path/to/hermes/python/site-packages/hermes_cli -name "SKILL.md"
```

## 常见误判

| 误判 | 真相 |
|------|------|
| `hermes skills list` 显示 source=local → "这是我装的" | 可能是 profile 克隆时从全局复制的 |
| 全局目录里有的 → "这是 Hermes 自带的" | 用户可能后来安装到全局了（时间戳可区分） |
| profile 目录里有但全局没有 → "这是我的" | ✅ 这个判断基本正确 |

## 结论

**时间戳 + 目录对比**双验证最准确。不要单信 `hermes skills list` 的 Source 字段。
