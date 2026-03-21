# Claude Code 环境一键复刻指南

> 本文档用于在 **Claude Code** 中快速复刻完整的开发环境配置。
> 基于 Claude Code v2.1.80 | macOS | 导出日期：2026-03-21

---

## 使用方式

打开终端，启动 Claude Code，将下方对应步骤的 prompt 粘贴发送即可。Claude 会自动执行所有操作。

> 建议按顺序执行 Step 1 → Step 4，每步确认成功后再进行下一步。

---

## Step 1: 写入全局配置 settings.json

将以下内容发送给 Claude Code：

```
请帮我配置 Claude Code 全局设置。
将以下内容写入 ~/.claude/settings.json（如果文件已存在，请先备份再覆盖）：

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
      "ExitPlanMode",
      "mcp__Desktop_Commander__*",
      "mcp__Context7__*",
      "mcp__ToolUniverse__*",
      "mcp__Claude_in_Chrome__*",
      "mcp__Claude_Preview__*",
      "mcp__mcp-registry__*",
      "mcp__AWS_API_MCP_Server__*",
      "mcp__Figma__*"
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
    ]
  },
  "model": "sonnet",
  "hooks": {
    "Stop": [
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
            "command": "cat workflow-status.json 2>/dev/null || echo '{\"status\":\"no workflow state found\"}'"
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
  "enabledPlugins": {},
  "extraKnownMarketplaces": {
    "anthropic-agent-skills": {
      "source": { "source": "github", "repo": "anthropics/skills" }
    },
    "agentsys": {
      "source": { "source": "github", "repo": "agent-sh/agentsys" }
    },
    "claude-plugins-official": {
      "source": { "source": "github", "repo": "anthropics/claude-plugins-official" }
    }
  }
}

注意：
- permissions.allow 中的 MCP 权限按你实际使用的 MCP 服务器按需增删
- deny 列表是安全黑名单，防止危险命令执行
- hooks 说明：
  - Stop/SubagentStop: 自动 git stash 创建检查点
  - SessionStart: 读取 workflow-status.json 恢复断点
  - UserPromptSubmit: 提醒使用完整工具集
```

> 完成后重启 Claude Code 使配置生效，再继续 Step 2。

---

## Step 2: 写入全局指令 CLAUDE.md

将以下内容发送给 Claude Code：

```
请将以下内容写入 ~/.claude/CLAUDE.md（如果文件已存在，请先备份再覆盖）：

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

## Step 3: 安装 Marketplace 和插件

将以下内容发送给 Claude Code：

```
请帮我在 Claude Code 中安装以下必需插件。

第一步：添加 3 个 Marketplace：
- claude plugins marketplace add anthropics/claude-plugins-official
- claude plugins marketplace add anthropics/skills
- claude plugins marketplace add agent-sh/agentsys

第二步：从 claude-plugins-official 安装 10 个官方插件：
- superpowers（核心技能系统：TDD、调试、协作模式）
- gopls-lsp（Go 语言智能补全、诊断、跳转）
- commit-commands（/commit、/push、/pr 快捷命令）
- code-review（多 Agent 代码审查，带置信度评分）
- security-guidance（OWASP 安全漏洞检测与修复建议）
- claude-md-management（CLAUDE.md 质量审计与自动更新）
- explanatory-output-style（代码实现时附带设计决策说明）
- linear（Linear 任务管理集成）
- typescript-lsp（TypeScript 语言服务）
- skill-creator（自定义技能创建向导）

安装命令格式：claude plugins install <插件名>@claude-plugins-official

第三步：从 agentsys 安装第三方插件：
- ship（PR 创建 -> CI 监控 -> 自动合并全流程）

安装命令：claude plugins install ship@agentsys

第四步：安装完成后运行 claude plugins list 确认 11 个插件全部 enabled。
```

---

## Step 4: 安装系统依赖（按需）

将以下内容发送给 Claude Code：

```
请检查并安装以下系统依赖（已有的跳过）：

必需：
- Git >= 2.39（macOS 自带，确认版本即可）
- Go + gopls（gopls-lsp 插件需要）：brew install go && go install golang.org/x/tools/gopls@latest
- Node.js（typescript-lsp 插件需要）：brew install node

可选：
- claude-hooks（用 TypeScript 编写复杂 hook 逻辑，当前配置不需要）：brew install claude-hooks

请逐个检查是否已安装，缺少的才安装，已有的报告版本即可。
```

---

## Step 5: 验证全部配置

将以下内容发送给 Claude Code：

```
请验证 Claude Code 环境配置是否完整：

1. 运行 claude --version，确认版本
2. 运行 claude plugins marketplace list，确认有 3 个 marketplace：
   - claude-plugins-official
   - anthropic-agent-skills
   - agentsys
3. 运行 claude plugins list，确认 11 个插件全部 enabled
4. 读取 ~/.claude/settings.json，确认包含 permissions、hooks、extraKnownMarketplaces
5. 读取 ~/.claude/CLAUDE.md，确认包含语言要求、工作风格、验证规则、安全底线
6. 检查系统依赖：git --version、go version、gopls version、node --version

输出一份检查报告，标注每项是否通过。
```

---

## 配置速查表

### 权限模型

| 类别 | 说明 |
|------|------|
| `Bash(*)` | 允许所有 shell 命令（受 deny 黑名单约束） |
| `Read/Write/Edit/...` | 文件操作工具免确认 |
| `mcp__*` | 指定 MCP 服务器工具免确认 |
| `deny` 列表 | 阻止 `rm -rf /`、管道注入、磁盘擦除等危险命令 |

### Hooks

| 事件 | 触发时机 | 行为 |
|------|----------|------|
| Stop / SubagentStop | Claude 完成回答时 | 在 git 仓库中自动 `git stash` 创建检查点 |
| SessionStart | 新会话开始时 | 读取 `workflow-status.json` 恢复工作流断点 |
| UserPromptSubmit | 每次发送消息时 | 提醒使用完整工具集（MCP、搜索、规划模式等） |

### 插件一览

| 插件 | 来源 | 用途 |
|------|------|------|
| superpowers | official | 核心技能：TDD、调试、协作模式 |
| gopls-lsp | official | Go 语言服务 |
| typescript-lsp | official | TypeScript 语言服务 |
| commit-commands | official | `/commit` `/push` `/pr` 快捷命令 |
| code-review | official | 多 Agent 代码审查 |
| security-guidance | official | 安全漏洞检测 |
| claude-md-management | official | CLAUDE.md 管理 |
| explanatory-output-style | official | 设计决策说明 |
| linear | official | Linear 任务集成 |
| skill-creator | official | 自定义技能创建 |
| ship | agentsys | PR->CI->合并自动化 |

### CLAUDE.md 核心规则

| 规则 | 内容 |
|------|------|
| 语言 | 对话简体中文，代码/commit 英文 |
| 风格 | 直接执行、推荐方案、追踪根因 |
| 验证 | Go: `go vet` + `go test -race`；TS: `tsc --noEmit` |
| 安全 | 不硬编码密钥、不 push main、不用 panic() |

---

## 常见问题

**Q: 插件安装报 "not found in any configured marketplace"**
→ 先运行 `claude plugins marketplace list` 确认 marketplace 已添加。缺少则用 Step 3 的 prompt 重新添加。

**Q: Hook 报 `command not found` 错误**
→ 确认 settings.json 中的 hook command 是本文档中的 `git stash` 版本，而非旧的 `claudekit-hooks` 版本。

**Q: MCP 权限中的 UUID 型条目是什么**
→ 这些是 Claude Desktop 中自定义 MCP 服务器的实例 ID，每台机器不同。按需在 `permissions.allow` 中添加你自己的 `mcp__<server>__*`。

**Q: 想用 Opus 而不是 Sonnet**
→ 将 settings.json 中 `"model": "sonnet"` 改为 `"model": "opus"`。
