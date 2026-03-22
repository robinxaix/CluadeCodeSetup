# TalkLingo Claude Code 全局环境配置指南

> 本文档包含 Claude Code 全局配置（~/.claude/），供团队成员从零搭建同样的开发环境。
> 项目级配置（.claude/）已入 git，clone 仓库即可获得。
>
> 生成日期：2026-03-22

---

## 1. 环境概览

### 1.1 配置文件树状图

```
~/.claude/                          # 全局配置（用户级，本文档覆盖范围）
├── settings.json                   # 权限、hooks、插件、市场注册
├── mcpServers.json                 # MCP 服务器连接配置
└── CLAUDE.md                       # 全局工作指南
```

### 1.2 全局 vs 项目配置

| 层级 | 位置 | 作用 | 来源 |
|------|------|------|------|
| 全局 | `~/.claude/` | 用户级权限、通用 hooks、MCP 服务器、插件 | **本文档 + 安装脚本** |
| 项目 | `.claude/` + `CLAUDE.md` | hooks、rules、agents、skills | **git clone 自动获得** |

---

## 2. 前置条件

### 2.1 Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 2.2 Node.js (v18+)

```bash
node --version  # >= 18.x
```

### 2.3 gh CLI (GitHub MCP)

```bash
brew install gh
gh auth login
```

### 2.4 pnpm (前端检查)

```bash
npm install -g pnpm
```

### 2.5 Go 工具链

```bash
go version  # Go 1.26+
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/zeromicro/go-zero/tools/goctl@latest
```

### 2.6 可选：AgentSys

```bash
npm install -g agentsys
cargo install ast-grep
agentsys --tool claude
```

---

## 3. settings.json

**路径：** `~/.claude/settings.json`

```json
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
```

### 各字段说明

| 字段 | 说明 |
|------|------|
| `permissions.allow` | 白名单工具，`Bash(*)` 允许所有 bash 命令 |
| `permissions.deny` | 黑名单，阻止 rm -rf /、管道注入、磁盘擦除等危险命令 |
| `permissions.defaultMode` | 默认权限模式为 plan（需确认） |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | 启用 Agent Teams 实验功能 |
| `hooks.Stop` | 会话结束时自动 git stash 保存 + tmux 响铃通知 |
| `hooks.SubagentStop` | 子 Agent 结束时同样 git stash 保存 |
| `hooks.SessionStart` | 加载 workflow-status.json（AgentSys 工作流状态） |
| `hooks.UserPromptSubmit` | 每次提交时提醒可用工具集（Superpowers） |
| `enabledPlugins` | 11 个全局插件（详见下方插件清单） |
| `extraKnownMarketplaces` | 3 个插件市场（anthropics/skills, agentsys, claude-plugins-official） |
| `voiceEnabled` | 启用语音输入 |

---

## 4. mcpServers.json

**路径：** `~/.claude/mcpServers.json`

```json
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
```

### 各字段说明

| 字段 | 说明 |
|------|------|
| `servers.desktop-commander` | 本地文件系统和进程管理 |
| `servers.context7` | 技术文档查询（带缓存） |
| `servers.sonatype-guide` | 依赖安全扫描（CVE、许可证） |
| `global.circuitBreaker` | 熔断机制，连续 5 次失败后暂停 60s |
| `monitoring` | 启用性能和错误追踪，指标写入 `~/.claude/sessions/mcp-metrics.json` |

---

## 5. CLAUDE.md

**路径：** `~/.claude/CLAUDE.md`

```markdown
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
```

---

## 6. 全局插件清单

### 6.1 启用的插件

| 插件 | 来源 | 用途 |
|------|------|------|
| `superpowers` | claude-plugins-official | 增强工作流（brainstorming、TDD、plan 等） |
| `gopls-lsp` | claude-plugins-official | Go Language Server 集成 |
| `commit-commands` | claude-plugins-official | Git commit/push/PR 快捷命令 |
| `code-review` | claude-plugins-official | PR 代码审查 |
| `security-guidance` | claude-plugins-official | 安全编码指导 |
| `claude-md-management` | claude-plugins-official | CLAUDE.md 维护 |
| `explanatory-output-style` | claude-plugins-official | 教育性输出风格（Insight 面板） |
| `typescript-lsp` | claude-plugins-official | TypeScript Language Server |
| `skill-creator` | claude-plugins-official | Skill 创建和管理 |
| `ship` | agentsys | PR 创建/CI 监控/合并 |
| `telegram` | claude-plugins-official | Telegram 频道集成 |

### 6.2 插件市场

| 市场 ID | GitHub 仓库 | 说明 |
|---------|------------|------|
| `claude-plugins-official` | `anthropics/claude-plugins-official` | Anthropic 官方插件 |
| `agentsys` | `agent-sh/agentsys` | AgentSys 自动化插件 |
| `anthropic-agent-skills` | `anthropics/skills` | Anthropic Agent Skills |

插件通过 `enabledPlugins` 声明后，Claude Code 启动时自动从市场下载和加载。

---

## 7. 复刻验证 Checklist

安装完成后，逐项验证：

- [ ] `~/.claude/settings.json` 存在且 JSON 合法
- [ ] `~/.claude/mcpServers.json` 存在且 JSON 合法
- [ ] `~/.claude/CLAUDE.md` 存在
- [ ] `claude` 启动后 Stop hook 正常（会话结束时 git stash 自动保存）
- [ ] MCP 服务器连接正常（GitHub MCP 可通过 `gh` 操作 issue/PR）
- [ ] 所有插件加载（superpowers、gopls-lsp、commit-commands 等）
- [ ] 对话使用简体中文，commit message 使用英文
- [ ] Agent Teams 功能可用（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`）
