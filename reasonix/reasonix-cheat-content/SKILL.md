---
name: reasonix-cheat-content
description: 内容创作校准系统 — 评分→盲预测→发布→T+3d复盘→进化rubric。用于视频/长文/播客的内容创作优化循环。
category: reasonix
tags: [content-creation, prediction, scoring, rubric]
---

# Cheat on Content — 内容创作校准系统

把内容创作变成可校准的预测循环：**打分 → 盲预测 → 发布 → T+3d 复盘 → 进化 rubric**。

## 三条不可妥协原则

1. **盲预测**：预测必须在看到任何实际数据**之前**写完。一旦写完，预测段 immutable。
2. **升级 = 全量重打**：rubric 升级时，校准池所有有实绩数据的样本必须用新公式重打分。
3. **Rubric 是工作台不是博物馆**：被推翻或被吸收为正式维度的观察，删掉不留考古层。

## 路由表

| 用户说 | 调用子工作流 |
|--------|-------------|
| "初始化" / "首次使用" | **init** |
| "找对标" / "learn from" | **learn-from** |
| "找选题" / "seed" | **seed** |
| "打分这篇 [path]" | **score** |
| "启动预测" / "给这稿子打分并预测" | **predict** |
| "拍了 X" / "录完了" | **shoot** |
| "已发布" / "发布链接是 X" | **publish** |
| "复盘" / "T+3d 数据来了" | **retro** |
| "升级 rubric" / "bump" | **bump** |
| "推荐选题" | **recommend** |
| "抓热点" / "今天有什么可做的" | **trends** |
| "状态" / "看板" / "status" | **status** |

## 核心工作流

- **init**: 创建项目脚手架（rubric_notes.md, predictions/, samples/ 等）
- **score**: 按 rubric 七个维度打分，每维度写理由
- **predict**: 盲预测 → 写预测文件（含 bucket + 概率分布 + 反事实场景）
- **retro**: T+3d 复盘 → 对比预测 vs 实际 → 识别系统偏差
- **bump**: 校准池足够后升级 rubric

详见原 skill 文件 `~/.hermes/skills/reasonix-cheat-content.md` 获取完整子工作流细节。
