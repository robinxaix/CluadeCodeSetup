#!/bin/bash
# =============================================================================
# XcodeBuildMCP 一键安装脚本
# 适用于：macOS + Homebrew + 可能存在 HTTP 代理的开发环境
# 用法：bash install.sh [--with-proxy]
# =============================================================================

set -euo pipefail

WITH_PROXY=false
if [[ "${1:-}" == "--with-proxy" ]]; then
  WITH_PROXY=true
fi

XMCP_VERSION="2.3.2"
NODE_BIN="$(which node 2>/dev/null || echo /opt/homebrew/bin/node)"
WRAPPER_PATH="/opt/homebrew/bin/xcodebuildmcp-wrapper"

log() { echo "[xmcp-install] $*"; }
ok()  { echo "[xmcp-install] ✓ $*"; }
err() { echo "[xmcp-install] ✗ $*" >&2; exit 1; }

# ── 1. 检查前置条件 ──────────────────────────────────────────────────────────
log "检查前置条件..."

command -v node >/dev/null 2>&1 || err "未找到 node，请先安装：brew install node"
command -v npm  >/dev/null 2>&1 || err "未找到 npm"
command -v xcodebuild >/dev/null 2>&1 || err "未找到 xcodebuild，请安装 Xcode Command Line Tools"
ok "前置条件满足（node=$(node --version), npm=$(npm --version)）"

# ── 2. 安装 xcodebuildmcp ────────────────────────────────────────────────────
log "安装 xcodebuildmcp@${XMCP_VERSION}..."
npm install -g "xcodebuildmcp@${XMCP_VERSION}"
ok "xcodebuildmcp@${XMCP_VERSION} 安装完成"

# ── 3. 创建 wrapper 脚本（代理环境必须）──────────────────────────────────────
log "创建 wrapper 脚本：${WRAPPER_PATH}"

XMCP_CLI="$(npm root -g)/xcodebuildmcp/build/cli.js"
[[ -f "$XMCP_CLI" ]] || XMCP_CLI="/opt/homebrew/lib/node_modules/xcodebuildmcp/build/cli.js"

if $WITH_PROXY; then
  # 代理模式：unset 代理变量 + 写诊断日志
  cat > "$WRAPPER_PATH" << WRAPPER
#!/bin/bash
# XcodeBuildMCP wrapper — 代理环境专用
# 取消代理变量，防止干扰 MCP stdio 通信
exec 3>/tmp/xmcp-debug.log
echo "[\$(date -u +%Y-%m-%dT%H:%M:%SZ)] STARTED PID=\$\$" >&3
echo "[\$(date -u +%Y-%m-%dT%H:%M:%SZ)] HTTP_PROXY=\${HTTP_PROXY:-not set}" >&3

unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy

exec ${NODE_BIN} ${XMCP_CLI} "\$@"
WRAPPER
else
  # 标准模式
  cat > "$WRAPPER_PATH" << WRAPPER
#!/bin/bash
# XcodeBuildMCP wrapper
exec ${NODE_BIN} ${XMCP_CLI} "\$@"
WRAPPER
fi

chmod +x "$WRAPPER_PATH"
ok "wrapper 脚本创建完成：${WRAPPER_PATH}"

# ── 4. 验证安装 ───────────────────────────────────────────────────────────────
log "验证安装..."
INSTALLED_VER=$(node "$XMCP_CLI" --version 2>/dev/null || echo "unknown")
ok "xcodebuildmcp 版本：${INSTALLED_VER}"

# ── 5. 运行诊断 ───────────────────────────────────────────────────────────────
log "运行 xcodebuildmcp-doctor..."
xcodebuildmcp-doctor || true

echo ""
echo "======================================================"
echo "  XcodeBuildMCP 安装完成！"
echo ""
echo "  下一步："
echo "  1. 将 mcp.json 复制到 iOS 项目根目录"
echo "  2. 将 settings.local.json 复制到 .claude/ 目录"
echo "  3. 在 Claude Code 中运行：请设置 XcodeBuildMCP session 默认值"
echo "======================================================"
