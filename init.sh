#!/bin/bash
# =============================================================================
# fbc-starter 微服务规范初始化脚本
#
# 用法:
#   bash init.sh [目标目录]
#
# 如果不指定目标目录，默认为当前目录。
# =============================================================================

set -e

# ---------- 颜色定义 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---------- 脚本所在目录（用于定位模板文件） ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"

# 转为绝对路径
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo -e "${RED}❌ 目标目录不存在: $1${NC}"
    exit 1
}

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 fbc-starter 微服务开发规范初始化                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  目标目录: ${GREEN}${TARGET_DIR}${NC}"
echo ""

# ---------- 检查模板文件是否存在 ----------
if [ ! -d "$SCRIPT_DIR/.aiproject" ]; then
    echo -e "${RED}❌ 未找到 .aiproject 规范目录，请确认脚本位置正确${NC}"
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/templates" ]; then
    echo -e "${RED}❌ 未找到 templates 模板目录，请确认脚本位置正确${NC}"
    exit 1
fi

# ---------- 检查是否已存在 .aiproject ----------
if [ -d "$TARGET_DIR/.aiproject" ]; then
    echo -e "${YELLOW}⚠️  目标目录已存在 .aiproject 目录${NC}"
    read -p "  是否覆盖？(y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  跳过 .aiproject 复制${NC}"
        SKIP_AIPROJECT=true
    fi
fi

# ---------- 复制 .aiproject 规范文件 ----------
if [ "$SKIP_AIPROJECT" != "true" ]; then
    echo ""
    echo -e "${BLUE}📋 复制 .aiproject 规范文件...${NC}"
    cp -r "$SCRIPT_DIR/.aiproject" "$TARGET_DIR/"
    echo -e "${GREEN}  ✅ .aiproject/ (README.md + P0-P9)${NC}"
fi

# ---------- 选择 AI 工具 ----------
echo ""
echo -e "${BLUE}🤖 选择你使用的 AI 编码工具（多选，用空格分隔编号）:${NC}"
echo ""
echo -e "  ${CYAN}1)${NC} Cursor          → .cursorrules + .cursor/rules/"
echo -e "  ${CYAN}2)${NC} GitHub Copilot  → .github/copilot-instructions.md"
echo -e "  ${CYAN}3)${NC} Gemini          → .gemini/settings.json + styleguide.md"
echo -e "  ${CYAN}4)${NC} Claude Code     → CLAUDE.md"
echo -e "  ${CYAN}5)${NC} Windsurf        → .windsurfrules"
echo -e "  ${CYAN}6)${NC} Cline           → .clinerules"
echo -e "  ${CYAN}7)${NC} 全部安装"
echo ""
read -p "  请输入编号 (例如: 1 3 4): " -a choices

# 如果选择了 7（全部），展开为 1-6
for choice in "${choices[@]}"; do
    if [ "$choice" = "7" ]; then
        choices=(1 2 3 4 5 6)
        break
    fi
done

echo ""

# ---------- 安装函数 ----------
install_cursor() {
    echo -e "${BLUE}  📦 Cursor${NC}"
    cp "$SCRIPT_DIR/templates/cursorrules" "$TARGET_DIR/.cursorrules"
    echo -e "${GREEN}    ✅ .cursorrules${NC}"
    mkdir -p "$TARGET_DIR/.cursor/rules"
    cp "$SCRIPT_DIR/templates/cursor_rules.md" "$TARGET_DIR/.cursor/rules/fbc-starter.md"
    echo -e "${GREEN}    ✅ .cursor/rules/fbc-starter.md${NC}"
}

install_copilot() {
    echo -e "${BLUE}  📦 GitHub Copilot${NC}"
    mkdir -p "$TARGET_DIR/.github"
    cp "$SCRIPT_DIR/templates/copilot_instructions.md" "$TARGET_DIR/.github/copilot-instructions.md"
    echo -e "${GREEN}    ✅ .github/copilot-instructions.md${NC}"
}

install_gemini() {
    echo -e "${BLUE}  📦 Gemini Code Assist${NC}"
    mkdir -p "$TARGET_DIR/.gemini"
    cp "$SCRIPT_DIR/templates/gemini_settings.json" "$TARGET_DIR/.gemini/settings.json"
    cp "$SCRIPT_DIR/templates/gemini_styleguide.md" "$TARGET_DIR/.gemini/styleguide.md"
    echo -e "${GREEN}    ✅ .gemini/settings.json${NC}"
    echo -e "${GREEN}    ✅ .gemini/styleguide.md${NC}"
}

install_claude() {
    echo -e "${BLUE}  📦 Claude Code${NC}"
    cp "$SCRIPT_DIR/templates/claude.md" "$TARGET_DIR/CLAUDE.md"
    echo -e "${GREEN}    ✅ CLAUDE.md${NC}"
}

install_windsurf() {
    echo -e "${BLUE}  📦 Windsurf${NC}"
    cp "$SCRIPT_DIR/templates/windsurfrules" "$TARGET_DIR/.windsurfrules"
    echo -e "${GREEN}    ✅ .windsurfrules${NC}"
}

install_cline() {
    echo -e "${BLUE}  📦 Cline${NC}"
    cp "$SCRIPT_DIR/templates/clinerules" "$TARGET_DIR/.clinerules"
    echo -e "${GREEN}    ✅ .clinerules${NC}"
}

# ---------- 执行安装 ----------
installed=0
for choice in "${choices[@]}"; do
    case "$choice" in
        1) install_cursor; installed=$((installed + 1)) ;;
        2) install_copilot; installed=$((installed + 1)) ;;
        3) install_gemini; installed=$((installed + 1)) ;;
        4) install_claude; installed=$((installed + 1)) ;;
        5) install_windsurf; installed=$((installed + 1)) ;;
        6) install_cline; installed=$((installed + 1)) ;;
        *) echo -e "${YELLOW}  ⚠️  未知选项: $choice，已跳过${NC}" ;;
    esac
done

# ---------- 更新 .gitignore（可选）----------
echo ""
if [ -f "$TARGET_DIR/.gitignore" ]; then
    # 检查是否已包含 .aiproject 相关条目（|| true 防止 grep 无匹配时 set -e 退出）
    has_aiproject=$(grep -c ".aiproject" "$TARGET_DIR/.gitignore" 2>/dev/null || true)
    if [ "$has_aiproject" = "0" ]; then
        add_gitignore=""
        read -p "  是否将 AI 工具配置加入 .gitignore？(y/N): " add_gitignore 2>/dev/null || true
        if [[ "$add_gitignore" =~ ^[Yy]$ ]]; then
            echo "" >> "$TARGET_DIR/.gitignore"
            echo "# AI 工具配置（项目级规范应提交到仓库）" >> "$TARGET_DIR/.gitignore"
            echo "# 如需共享规范，请注释掉以下行" >> "$TARGET_DIR/.gitignore"
            echo "# .cursorrules" >> "$TARGET_DIR/.gitignore"
            echo "# .cursor/" >> "$TARGET_DIR/.gitignore"
            echo "# .windsurfrules" >> "$TARGET_DIR/.gitignore"
            echo "# .clinerules" >> "$TARGET_DIR/.gitignore"
            echo "# CLAUDE.md" >> "$TARGET_DIR/.gitignore"
            echo -e "${GREEN}  ✅ 已更新 .gitignore（AI 配置默认提交，如需忽略请取消注释）${NC}"
        fi
    fi
fi

# ---------- 完成 ----------
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ✅ 初始化完成！                                       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  已安装 ${GREEN}${installed}${NC} 个 AI 工具配置"
echo ""
echo -e "  📖 规范文件位于: ${GREEN}${TARGET_DIR}/.aiproject/${NC}"
echo -e "  📖 规范总览:     ${GREEN}${TARGET_DIR}/.aiproject/STANDARDS.md${NC}"
echo ""
echo -e "  ${YELLOW}💡 提示: 建议将 .aiproject/ 和 AI 工具配置提交到 Git 仓库，${NC}"
echo -e "  ${YELLOW}   这样团队中所有开发者和 AI 工具都能读取规范。${NC}"
echo ""
