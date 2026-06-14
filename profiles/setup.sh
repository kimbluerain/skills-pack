#!/bin/bash
set -e

echo "========================================"
echo "  Hermes Profile & Skill 一键安装脚本"
echo "========================================"
echo ""

# ─── 收集信息 ─────────────────────────────
read -p "你的名字（英文，如 Kim）： " USER_NAME
USER_NAME_LOWER=$(echo "$USER_NAME" | tr '[:upper:]' '[:lower:]')
read -p "项目主目录（如 ~/projects）： " PROJECT_DIR
PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"

echo ""
echo "已确认："
echo "  用户名: $USER_NAME"
echo "  项目目录: $PROJECT_DIR"
echo ""

# ─── 检查 hermes ──────────────────────────
if ! command -v hermes &> /dev/null; then
    echo "❌ 未找到 hermes CLI。请先安装 Hermes Agent。"
    exit 1
fi

# ─── 创建 profile ─────────────────────────
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"

create_profile() {
    local name=$1
    local model=$2
    echo "→ 创建 profile: $name (模型: $model)"

    hermes profile create "$name" --description "$3" 2>/dev/null || true

    # 替换模板变量并写入
    local tpl="$TEMPLATE_DIR/$name/config.template.yaml"
    local dest="$HOME/.hermes/profiles/$name/config.yaml"

    if [ -f "$tpl" ]; then
        sed "s|\$HOME|$HOME|g; s|projects/|$PROJECT_DIR/|g" "$tpl" > "$dest"
        echo "  ✓ config.yaml 已就绪"
    fi

    # SOUL.md
    local soul_tpl="$TEMPLATE_DIR/$name/SOUL.template.md"
    local soul_dest="$HOME/.hermes/profiles/$name/SOUL.md"
    if [ -f "$soul_tpl" ]; then
        sed "s|{{USER_NAME}}|$USER_NAME|g; s|{{USER_NAME_LOWER}}|$USER_NAME_LOWER|g" "$soul_tpl" > "$soul_dest"
        echo "  ✓ SOUL.md 已就绪"
    fi
}

# 大管家
create_profile "panam" "deepseek-v4-pro" "大管家：任务调度、验收、兜底"

# 杠精
create_profile "johnny" "mimo-v2.5" "摇滚反叛者：找茬、反驳、直到无话可说"

# 调研员
create_profile "researcher" "mimo-v2.5" "调研分析专家：查资料、技术对比、出报告"

# 程序员
create_profile "coder" "qwen3.7-max" "写代码的执行者：用 reasonix 写生产代码"

# 审查员
create_profile "reviewer" "qwen3.7-max" "代码审查：审查代码、检查一致性"

# ─── 安装 reasonix skill ──────────────────
echo ""
echo "→ 安装 reasonix skill 包..."
SKILLS_DIR="$HOME/.hermes/skills/reasonix"
if [ -d "$SKILLS_DIR" ]; then
    rm -rf "$SKILLS_DIR"
fi
cp -r "$TEMPLATE_DIR/../reasonix" "$SKILLS_DIR"
echo "  ✓ reasonix skill 已安装到 $SKILLS_DIR"

# ─── 完成 ─────────────────────────────────
echo ""
echo "========================================"
echo "  ✅ 全部完成！"
echo "========================================"
echo ""
echo "可用命令："
echo "  panam chat        # 跟大管家对话"
echo "  johnny chat       # 找强尼抬杠"
echo "  researcher chat   # 启动调研"
echo "  coder chat        # 派发编程任务"
echo "  reviewer chat     # 代码审查"
echo ""
echo "⚠️  每个 profile 还需要单独配置 API key："
echo "   cd ~/.hermes/profiles/<name>"
echo "   echo 'YOUR_API_KEY=xxx' >> .env"
echo "   或直接编辑 config.yaml 里的 api_key 字段"
echo ""
echo "📦 Reasonix skill 位置: $SKILLS_DIR"
