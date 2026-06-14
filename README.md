# Kim's Skills Pack

跨 Agent 通用技能包 —— 适用于 **Hermes Agent**、**Claude Code**、**Codex** 等 AI Agent 框架。

## 📦 包含什么

### 🔬 Reasonix 系列（核心推理框架）

| 技能 | 用途 |
|------|------|
| `reasonix-sop` | 任务执行标准流程：澄清→扫描→规划→执行→检查 |
| `reasonix-analysis` | 四维分析引擎：芒格/塔勒布/费曼/纳瓦尔同时分析 |
| `reasonix-superpower` | 系统化 AI 开发工作流：设计先行→子 agent 驱动→TDD |
| `reasonix-last30days` | 跨平台最近 30 天调研：HN/YouTube/Reddit/X |
| `reasonix-memory-box` | 本地化记忆管理：自动总结、去重、画像维护 |
| `reasonix-cheat-content` | 内容创作校准：评分→盲预测→发布→复盘 |
| `reasonix-codegraph` | CodeGraph MCP 使用指南 |
| `reasonix-ppt-master` | AI 驱动 PPT 生成：PDF/DOCX→SVG→多角色协作 |
| `reasonix-fengge` | 峰哥思维操作系统（B站纪录片创作者风格） |
| `reasonix-huashu-nuwa` | 女娲造人：输入人名→生成人物 Skill |

### 🔧 跨 Agent 协作

| 技能 | 用途 |
|------|------|
| `cross-agent-skill-sync` | 在 Hermes/Claude Code/Reasonix 间同步 skill |
| `implementation-workflow` | 完整软件开发生命周期：plan→spike→implement |

### 🛠 Hermes 运维

| 技能 | 用途 |
|------|------|
| `hermes-webui-ops` | Hermes Web UI 运维：数据库直连、日志分析、配置管理 |
| `hermes-group-chat` | Hermes 群聊功能调试：@提及机制、数据库操作、问题排查 |

### 📋 工具

| 技能 | 用途 |
|------|------|
| `github-workflow` | GitHub 完整工作流：PR、Issue、Code Review |

---

## 🚀 安装

### Hermes Agent

```bash
# 方式一：直接克隆到 skills 目录
cd ~/.hermes/skills
git clone https://github.com/kimbluerain/skills-pack.git kim-skills

# 方式二：作为外部 skill 源
hermes skills tap add https://github.com/kimbluerain/skills-pack
```

### Claude Code

```bash
# 复制到 Claude 的 skills 目录
cp -r reasonix/* ~/.claude/skills/
```

### 通用（手动）

所有 skill 都是标准 `SKILL.md` 格式（YAML frontmatter + Markdown），任何支持此格式的 Agent 框架都可以直接使用：

```
skills-pack/
├── reasonix/
│   ├── reasonix-sop/SKILL.md
│   └── ...
├── cross-agent/
├── development/
├── github/
└── hermes-ops/
```

---

## 📐 Skill 格式

每个 skill 遵循标准格式：

```markdown
---
name: skill-name
description: "一句话描述"
category: category-name
tags: [tag1, tag2]
---

# Skill 标题

详细内容...
```

---

## 🔄 更新

```bash
cd ~/.hermes/skills/kim-skills
git pull
```

---

## 📝 定制

所有 skill 已做通用化处理——不包含特定用户名、路径或 Agent 绑定。如需修改：

1. Fork 本仓库
2. 编辑对应 `SKILL.md`
3. 提交 PR 或自行维护分支
