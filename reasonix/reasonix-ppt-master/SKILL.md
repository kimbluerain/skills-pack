---
name: reasonix-ppt-master
description: AI驱动PPT生成系统。将PDF/DOCX/URL/Markdown源文档转换为高质量SVG页面，通过多角色协作（策略师→执行器→质检）导出为PPTX。
category: reasonix
tags: [presentation, ppt, svg, document-conversion]
---

# ppt-master — AI 驱动 PPT 生成系统

## 作用

将 PDF/DOCX/URL/Markdown 源文档转换成高质量的 SVG 页面，通过多角色协作（策略师→执行器→质检）导出为 PPTX。

## 触发条件

用户说「创建PPT」「做PPT」「生成PPT」「制作演示文稿」「make presentation」或提到「ppt-master」。

## 核心流程

1. 创建项目 → 2. 策略师（结构设计）+ 图片生成 → 3. 执行器（逐页手写 SVG）→ 4. 质检 → 5. 后处理 → 6. 导出 PPTX

## 约束

- 严格串行执行，8 条铁律
- SVG 必须手写，禁止脚本批量生成
- 全局设计上下文存 spec_lock.md，每页重新读取

## 依赖

- Python: python-pptx, cairosvg, edge-tts
- .env: 图片生成后端（OpenAI/Gemini/通义/智谱/火山引擎）

完整 skill 位于 `~/.reasonix/skills/ppt-master/SKILL.md`（文件夹格式含完整工作流）。
