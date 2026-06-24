# Hermes Skill 来源判定方法

## 问题

`hermes skills list` 的 Source 列（builtin/local/official）不可靠——`local` 不代表用户手动安装，可能是 profile 创建时从全局克隆的副本。

## 正确方法

### 三步判定法

**第一步：全局目录对比**

```bash
# 全局 skills（Hermes 出厂内置 + 用户全局安装）
ls ~/.hermes/skills/

# 当前 profile skills
ls ~/.hermes/profiles/<name>/skills/
```

只在 profile 目录存在的 → **用户手动加的**
全局目录也存在的 → 继续第二步

**第二步：时间戳分析**

```bash
# Hermes 安装日期通常是最早的文件日期
find ~/.hermes/skills -name "SKILL.md" -newermt "YYYY-MM-DD" ! -newermt "YYYY-MM-DD+1"

# 后期安装的 skill 会有更晚的时间戳
find ~/.hermes/skills -name "SKILL.md" -newermt "YYYY-MM-DD+1"
```

出厂内置：安装日期的文件
用户安装：明显晚于安装日期的文件

**第三步：Python 包验证（最终手段）**

```bash
find /path/to/hermes/site-packages -path "*/skills*" -name "SKILL.md"
```

Python 包里有的 → 100% Hermes 出厂内置

### 常见陷阱

- ❌ 不要信 `hermes skills list` 的 `local` 标签
- ❌ 不要凭记忆判断（尤其 reasonix-* 这类看起来像自定义的其实可能是内置）
- ✅ 文件系统对比 + 时间戳 = 唯一可靠的方法

## 示例

本次 session 中，Kim 的 skill 分布：
- 73 个在全局目录 = Hermes 出厂
- 26 个时间戳晚于安装日 = Kim 后期装的
- 3 个仅在 panam profile 目录 = Kim 手动创建的
