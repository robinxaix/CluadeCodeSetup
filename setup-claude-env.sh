#!/bin/bash
set -euo pipefail

# ============================================================================
# TalkLingo Claude Code 全局环境一键安装脚本
#
# 用途：为团队成员安装 ~/.claude/ 下的全局配置
# 项目配置（.claude/）已入 git，clone 仓库即可获得
#
# 用法：bash setup-claude-env.sh
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

GLOBAL_CLAUDE_DIR="$HOME/.claude"

# ── 前置条件检查 ──────────────────────────────────────────────
check_prerequisites() {
  info "检查前置条件..."
  local missing=()

  if ! command -v claude &>/dev/null; then
    missing+=("claude (npm install -g @anthropic-ai/claude-code)")
  fi

  if ! command -v node &>/dev/null; then
    missing+=("node (https://nodejs.org/)")
  else
    local node_major
    node_major=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$node_major" -lt 18 ]; then
      missing+=("node >= 18 (current: $(node -v))")
    fi
  fi

  if ! command -v gh &>/dev/null; then
    missing+=("gh CLI (brew install gh)")
  fi

  if ! command -v go &>/dev/null; then
    missing+=("go (https://go.dev/dl/)")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    error "缺少以下依赖："
    for dep in "${missing[@]}"; do
      echo "  - $dep"
    done
    echo ""
    read -p "是否继续安装？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    ok "所有前置条件满足"
  fi
}

# ── 写入 settings.json ───────────────────────────────────────
setup_settings() {
  local target="$GLOBAL_CLAUDE_DIR/settings.json"

  if [ -f "$target" ]; then
    warn "$target 已存在，跳过（避免覆盖个人配置）"
    warn "如需更新，请手动参考 claude-code-setup-guide.md"
    return
  fi

  cat > "$target" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Write",
      "Edit",
      "MultiEdit",
      "Glob",
      "Grep",
      "WebFetch",
      "WebSearch",
      "TodoWrite",
      "Task",
      "NotebookEdit",
      "Skill",
      "EnterPlanMode",
      "ExitPlanMode"
    ],
    "deny": [
      "Bash(rm -rf /*)",
      "Bash(rm -rf /)",
      "Bash(sudo rm -rf *)",
      "Bash(sudo rm -rf /*)",
      "Bash(sudo rm -rf /)",
      "Bash(*| bash)",
      "Bash(*| sh)",
      "Bash(*| zsh)",
      "Bash(curl *| bash*)",
      "Bash(curl *| sh*)",
      "Bash(wget *| bash*)",
      "Bash(wget *| sh*)",
      "Bash(chmod 777 *)",
      "Bash(mkfs*)",
      "Bash(dd if=*of=/dev/*)",
      "Bash(> /dev/sda)",
      "Bash(sudo dd *)",
      "Bash(echo *> /etc/passwd)",
      "Bash(echo *> /etc/shadow)"
    ],
    "defaultMode": "plan"
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "git rev-parse --git-dir >/dev/null 2>&1 && git stash push -m \"claude-checkpoint-$(date +%Y%m%d%H%M%S)\" --include-untracked 2>/dev/null; true"
          },
          {
            "type": "command",
            "command": "[ -n \"$TMUX_PANE\" ] && tty_path=$(tmux display-message -p -t \"$TMUX_PANE\" '#{pane_tty}') && printf '\\a' > \"$tty_path\"; true",
            "timeout": 10
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "git rev-parse --git-dir >/dev/null 2>&1 && git stash push -m \"claude-checkpoint-$(date +%Y%m%d%H%M%S)\" --include-untracked 2>/dev/null; true"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f workflow-status.json ] && cat workflow-status.json; exit 0"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '>> Superpowers Skill Check: Remember to leverage your full toolkit - MCP servers, web search, planning mode, and sub-agents are all available.'"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "gopls-lsp@claude-plugins-official": true,
    "commit-commands@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "security-guidance@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true,
    "explanatory-output-style@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "skill-creator@claude-plugins-official": true,
    "ship@agentsys": true,
    "telegram@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {
    "anthropic-agent-skills": {
      "source": {
        "source": "github",
        "repo": "anthropics/skills"
      }
    },
    "agentsys": {
      "source": {
        "source": "github",
        "repo": "agent-sh/agentsys"
      }
    },
    "claude-plugins-official": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-plugins-official"
      }
    }
  },
  "voiceEnabled": true
}
EOF
  ok "$target 已创建"
}

# ── 写入 mcpServers.json ─────────────────────────────────────
setup_mcp() {
  local target="$GLOBAL_CLAUDE_DIR/mcpServers.json"

  if [ -f "$target" ]; then
    warn "$target 已存在，跳过"
    return
  fi

  cat > "$target" << 'EOF'
{
  "servers": {
    "desktop-commander": {
      "enabled": true,
      "timeout": 30000,
      "retries": 2,
      "description": "本地文件、进程、搜索操作"
    },
    "context7": {
      "enabled": true,
      "timeout": 15000,
      "cache": true,
      "description": "文档库查询（Go、go-zero、MySQL、Redis、ClickHouse 等官方文档）"
    },
    "sonatype-guide": {
      "enabled": true,
      "timeout": 15000,
      "description": "依赖安全检查（CVE、许可证）"
    }
  },
  "global": {
    "logLevel": "info",
    "defaultTimeout": 30000,
    "retryStrategy": "exponential",
    "maxRetries": 2,
    "circuitBreaker": {
      "enabled": true,
      "threshold": 5,
      "timeout": 60000
    }
  },
  "monitoring": {
    "enabled": true,
    "metricsPath": "~/.claude/sessions/mcp-metrics.json",
    "trackPerformance": true,
    "trackErrors": true
  }
}
EOF
  ok "$target 已创建"
}

# ── 写入 CLAUDE.md ───────────────────────────────────────────
setup_claude_md() {
  local target="$GLOBAL_CLAUDE_DIR/CLAUDE.md"

  if [ -f "$target" ]; then
    warn "$target 已存在，跳过"
    return
  fi

  cat > "$target" << 'EOF'
# 全局 Claude 工作指南

## 语言要求（最高优先级）

**所有与用户交互的内容必须使用简体中文**，包括：
- 对话回复、解释、分析、建议
- 错误信息说明和排查步骤
- TodoWrite 任务描述
- 进度说明（"正在分析…"、"已完成…"）

**保持英文**（行业惯例）：
- Git commit message（`feat: add xxx`）
- 代码变量名、函数名、类名
- 技术术语缩写（API、TDD、gRPC 等）

## 工作风格

- 直接执行，不需要每步都等待确认（已配置 Bash(*) 白名单）
- 遇到多个方案时给出推荐并说明理由，默认用推荐方案
- 错误排查时给出根本原因，不只是表面修复
- 使用 TodoWrite 追踪多步骤任务的进度

## 完成前强制验证

**宣告任何代码任务"完成"之前，必须运行验证命令：**

- Go 有改动：`go vet ./...` + `go test -race ./...`
- TypeScript 有改动：`npx tsc --noEmit` + 测试
- Shell/YAML 有改动：手工审查语法

## 安全底线

- 不硬编码 secrets（API Key、密码、私钥）
- 不直接 push main，所有变更通过 PR
- 涉及生产数据库（MySQL/MongoDB/Redis）操作前必须确认
- 禁止 panic() 在生产代码中使用，改用 error return
EOF
  ok "$target 已创建"
}

# ── GitHub CLI 登录检查 ───────────────────────────────────────
check_gh_auth() {
  info "检查 GitHub CLI 认证..."
  if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null; then
      ok "GitHub CLI 已登录"
    else
      warn "GitHub CLI 未登录，请运行: gh auth login"
    fi
  else
    warn "gh CLI 未安装，跳过"
  fi
}

# ── 可选：安装 AgentSys ──────────────────────────────────────
install_agentsys() {
  info "AgentSys 安装（可选）"
  echo "  AgentSys 提供自动化工作流（/next-task、/ship、/audit-project 等）"
  echo ""
  read -p "是否安装 AgentSys？(y/N) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v npm &>/dev/null; then
      info "安装 agentsys..."
      npm install -g agentsys && ok "agentsys 已安装" || warn "agentsys 安装失败"
    else
      warn "npm 不可用，跳过"
    fi

    if command -v cargo &>/dev/null; then
      info "安装 ast-grep..."
      cargo install ast-grep && ok "ast-grep 已安装" || warn "ast-grep 安装失败"
    else
      warn "cargo 不可用，跳过 ast-grep（repo-map 功能需要）"
    fi

    if command -v agentsys &>/dev/null; then
      info "注册 AgentSys 到 Claude Code..."
      agentsys --tool claude && ok "AgentSys 已注册" || warn "注册失败"
    fi
  else
    info "跳过 AgentSys 安装"
  fi
}

# ── 验证 ──────────────────────────────────────────────────────
run_verification() {
  info "运行最终验证..."
  echo ""

  local pass=0
  local fail=0

  for f in settings.json mcpServers.json CLAUDE.md; do
    if [ -f "$GLOBAL_CLAUDE_DIR/$f" ]; then
      ok "~/.claude/$f"
      ((pass++))
    else
      error "缺失: ~/.claude/$f"
      ((fail++))
    fi
  done

  # 验证 JSON 合法性
  for f in settings.json mcpServers.json; do
    if [ -f "$GLOBAL_CLAUDE_DIR/$f" ]; then
      if python3 -m json.tool "$GLOBAL_CLAUDE_DIR/$f" >/dev/null 2>&1; then
        ok "~/.claude/$f JSON 合法"
        ((pass++))
      else
        error "~/.claude/$f JSON 格式错误"
        ((fail++))
      fi
    fi
  done

  echo ""
  echo "============================================"
  if [ "$fail" -eq 0 ]; then
    ok "全部验证通过！($pass/$pass)"
    echo ""
    echo "现在可以 clone 项目仓库并在项目目录运行 'claude' 启动。"
    echo "首次启动时，插件会自动从市场下载。"
  else
    warn "验证结果: $pass 通过, $fail 失败"
    echo ""
    echo "请参考 claude-code-setup-guide.md 修复失败项。"
  fi
  echo "============================================"
}

# ── 主流程 ────────────────────────────────────────────────────
main() {
  echo ""
  echo "============================================"
  echo " TalkLingo Claude Code 全局环境安装"
  echo " 范围: ~/.claude/ (settings + MCP + CLAUDE.md)"
  echo "============================================"
  echo ""

  check_prerequisites
  echo ""

  mkdir -p "$GLOBAL_CLAUDE_DIR"

  info "=== 写入全局配置 ==="
  setup_settings
  setup_mcp
  setup_claude_md
  echo ""

  check_gh_auth
  echo ""

  install_agentsys
  echo ""

  run_verification
}

main "$@"
