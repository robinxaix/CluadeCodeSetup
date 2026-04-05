# XcodeBuildMCP 安装与配置指南

XcodeBuildMCP 是 Claude Code 与 Xcode 工具链的桥接层，让 Claude 可以直接调用 xcodebuild、模拟器、调试器、UI 自动化等能力，无需通过 Bash 命令间接操作。

---

## 一、安装 XcodeBuildMCP

### 前置条件
- macOS（Apple Silicon 或 Intel）
- Node.js 18+（推荐通过 Homebrew 安装）
- Xcode 已安装并完成命令行工具初始化
- Claude Code CLI 已安装

### 安装命令

```bash
# 全局安装 XcodeBuildMCP（当前版本 2.3.2）
npm install -g xcodebuildmcp

# 验证安装
xcodebuildmcp --version

# 运行诊断（检查环境是否就绪）
xcodebuildmcp-doctor
```

---

## 二、项目级 MCP 配置

在 iOS 项目根目录创建 `.mcp.json`：

### 标准配置（无代理）

```json
{
  "mcpServers": {
    "XcodeBuildMCP": {
      "type": "stdio",
      "command": "xcodebuildmcp",
      "args": ["mcp"],
      "env": {}
    }
  }
}
```

### 代理环境配置（需要绕过系统代理）

如果开发机设置了 HTTP 代理（如 Surge、Clash），xcodebuildmcp 的 stdio 通信会被代理干扰，需要用 wrapper 脚本绕过：

**第一步：创建 wrapper 脚本**

```bash
cat > /opt/homebrew/bin/xcodebuildmcp-wrapper << 'EOF'
#!/bin/bash
# 取消代理环境变量，防止干扰 MCP stdio 通信
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy

# 调用真正的 xcodebuildmcp（通过 node 直接执行）
exec /opt/homebrew/bin/node /opt/homebrew/lib/node_modules/xcodebuildmcp/build/cli.js "$@"
EOF

chmod +x /opt/homebrew/bin/xcodebuildmcp-wrapper
```

**第二步：`.mcp.json` 使用 wrapper**

```json
{
  "mcpServers": {
    "XcodeBuildMCP": {
      "type": "stdio",
      "command": "/bin/bash",
      "args": [
        "/opt/homebrew/bin/xcodebuildmcp-wrapper",
        "mcp"
      ],
      "env": {}
    }
  }
}
```

> **为什么需要 wrapper？**  
> Claude Code 启动 MCP server 时会继承 shell 环境变量。如果 `HTTP_PROXY` / `HTTPS_PROXY` 已设置，node 进程会尝试通过代理路由所有网络请求，导致与 Xcode 工具链的 stdio 通信失败。wrapper 在启动前 `unset` 这些变量，确保 MCP server 在干净的网络环境中运行。

---

## 三、Claude Code 项目权限配置

在项目根目录的 `.claude/settings.local.json` 中启用 MCP server 并配置必要权限：

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": [
    "XcodeBuildMCP"
  ],
  "permissions": {
    "allow": [
      "mcp__XcodeBuildMCP__session_show_defaults",
      "mcp__XcodeBuildMCP__build_sim",
      "Bash(xcrun simctl:*)",
      "Bash(xcodebuild test:*)",
      "Bash(xcodebuild build:*)"
    ]
  }
}
```

> **最小权限原则**：仅授权实际使用的工具，Claude Code 遇到未授权工具调用时会弹出确认对话框，避免意外执行。

---

## 四、CLAUDE.md 中声明 MCP 工具优先级

在项目 `CLAUDE.md` 的 `## Build Commands` 章节明确告知 Claude 使用 MCP 工具，避免退化到 Bash 命令：

```markdown
## Build Commands

- **Build**: Use `mcp__XcodeBuildMCP__build_sim` for simulator builds
- **Test**: Use `mcp__XcodeBuildMCP__test_sim` for running tests  
- **Clean**: Use `mcp__XcodeBuildMCP__clean` before major rebuilds
- **Logs**: Use `mcp__XcodeBuildMCP__start_sim_log_cap` to capture runtime logs
```

---

## 五、Session 默认值配置（推荐）

每次新对话开始时，先设置 session 默认值，避免每次调用都传重复参数：

```
# 在 Claude Code 对话中执行：
请设置 XcodeBuildMCP session 默认值：
- project: TalkLingo.xcodeproj
- scheme: TalkLingo
- simulator: iPhone 16
```

Claude 会调用 `mcp__XcodeBuildMCP__session_set_defaults`，之后的构建/测试命令无需再重复指定这些参数。

验证当前默认值：
```
请检查 XcodeBuildMCP session 默认配置
```

---

## 六、常见问题排查

### MCP server 无法启动

```bash
# 检查 node 路径
which node
/opt/homebrew/bin/node --version

# 检查 xcodebuildmcp 安装
ls /opt/homebrew/lib/node_modules/xcodebuildmcp/

# 运行诊断工具
xcodebuildmcp-doctor
```

### 代理环境下 MCP 工具调用超时

症状：Claude 调用 `mcp__XcodeBuildMCP__*` 工具后长时间无响应或报错。

解决：按「二、代理环境配置」步骤创建 wrapper 脚本，在 `.mcp.json` 中改用 wrapper。

### 模拟器未找到

```bash
# 列出可用模拟器
xcrun simctl list devices available

# 确认 session 默认配置中的模拟器名称与 xcrun 输出一致
```

### 构建失败但错误信息不完整

在 Claude Code 中运行：
```
/fix-build
```
Claude 会执行 clean build、捕获完整错误日志并逐一分析。

---

## 七、可用 MCP 工具速查

| 工具 | 用途 |
|------|------|
| `session_show_defaults` | 查看当前 session 默认配置 |
| `session_set_defaults` | 设置 project/scheme/simulator 默认值 |
| `build_sim` | 为模拟器构建 |
| `build_run_sim` | 构建并运行（模拟器） |
| `test_sim` | 在模拟器运行测试 |
| `clean` | 清除构建缓存 |
| `list_sims` | 列出可用模拟器 |
| `boot_sim` | 启动指定模拟器 |
| `screenshot` | 截取模拟器屏幕 |
| `start_sim_log_cap` | 开始捕获模拟器日志 |
| `stop_sim_log_cap` | 停止日志捕获 |
| `get_coverage_report` | 获取测试覆盖率报告 |
| `snapshot_ui` | 获取 UI 视图层级（含坐标） |
| `tap` / `swipe` / `type_text` | UI 自动化操作 |

完整工具列表参考：[XcodeBuildMCP GitHub](https://github.com/getsentry/XcodeBuildMCP)
