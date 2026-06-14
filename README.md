# Reasonix Skills Pack

跨 Agent 通用技能包 —— 适用于 **Hermes Agent**、**Claude Code**、**Codex** 等 AI Agent 框架。

## 📦 包含技能

| 技能 | 用途 |
|------|------|
| `reasonix-sop` | 任务执行标准流程：澄清→扫描→规划→执行→检查 |
| `reasonix-analysis` | 四维分析引擎：芒格/塔勒布/费曼/纳瓦尔同时分析 |
| `reasonix-superpower` | 系统化 AI 开发：设计先行→子 agent 驱动→TDD |
| `reasonix-last30days` | 跨平台最近 30 天调研：HN/YouTube/Reddit/X |
| `reasonix-memory-box` | 本地化记忆管理：自动总结、去重、画像维护 |
| `reasonix-cheat-content` | 内容创作校准：评分→盲预测→发布→复盘 |
| `reasonix-codegraph` | CodeGraph MCP 使用指南 |
| `reasonix-ppt-master` | AI 驱动 PPT 生成：PDF/DOCX→SVG→PPTX |
| `reasonix-fengge` | 峰哥思维操作系统（B站纪录片创作者风格） |
| `reasonix-huashu-nuwa` | 女娲造人：输入人名→生成人物 Skill |

## 🚀 安装

### Hermes Agent

```bash
# 方式一：直接克隆到 skills 目录
cd ~/.hermes/skills
git clone https://github.com/kimbluerain/skills-pack.git reasonix

# 方式二：作为外部 skill 源
hermes skills tap add https://github.com/kimbluerain/skills-pack
```

### 一键安装（含 Profile）

```bash
git clone https://github.com/kimbluerain/skills-pack.git
cd skills-pack/profiles
bash setup.sh
```

脚本交互式引导：输入你的名字 → 项目目录 → 自动创建 5 个 profile（panam/johnny/researcher/coder/reviewer）+ 安装 reasonix skill。

### 通用

所有 skill 都是标准 `SKILL.md` 格式（YAML frontmatter + Markdown），任何支持此格式的 Agent 框架都可以直接使用。

## 🔄 更新

```bash
cd ~/.hermes/skills/reasonix
git pull
```
