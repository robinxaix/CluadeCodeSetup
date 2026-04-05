#!/bin/bash
# =============================================================================
# XcodeBuildMCP wrapper — 代理环境专用
# 安装位置：/opt/homebrew/bin/xcodebuildmcp-wrapper
# 安装命令：
#   cp xcodebuildmcp-wrapper.sh /opt/homebrew/bin/xcodebuildmcp-wrapper
#   chmod +x /opt/homebrew/bin/xcodebuildmcp-wrapper
# =============================================================================
#
# 为什么需要这个 wrapper？
# Claude Code 启动 MCP server 时继承 shell 环境变量。
# 如果 HTTP_PROXY / HTTPS_PROXY 已设置（Surge、Clash 等代理工具），
# node 进程会尝试通过代理路由所有连接，导致 MCP stdio 通信阻塞或超时。
# 此 wrapper 在启动前 unset 这些变量，确保 xcodebuildmcp 在净网络环境运行。

# 取消所有代理变量
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy NO_PROXY no_proxy

# 可选：写诊断日志（排障时取消注释）
# exec 3>/tmp/xmcp-debug.log
# echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] STARTED PID=$$ ARGS=$*" >&3

# 通过 node 直接执行 xcodebuildmcp CLI，跳过全局 PATH 查找
exec /opt/homebrew/bin/node \
  /opt/homebrew/lib/node_modules/xcodebuildmcp/build/cli.js \
  "$@"
