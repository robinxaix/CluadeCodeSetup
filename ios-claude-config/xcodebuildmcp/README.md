# XcodeBuildMCP 可复用配置

从当前工作环境提取，可直接用于新 iOS 项目配置。

## 文件说明

| 文件 | 用途 |
|------|------|
| `install.sh` | 一键安装脚本（自动安装 npm 包 + 创建 wrapper） |
| `xcodebuildmcp-wrapper.sh` | wrapper 脚本源文件（代理环境专用） |
| `mcp.json` | 项目 MCP 配置（代理环境，使用 wrapper） |
| `mcp-no-proxy.json` | 项目 MCP 配置（无代理环境，直接调用） |
| `settings.local.json` | Claude Code 项目权限配置模板 |

---

## 快速上手

### 场景 A：新机器首次安装（有代理）

```bash
# 1. 运行安装脚本
bash install.sh --with-proxy

# 2. 将 mcp.json 复制到 iOS 项目根目录
cp mcp.json /path/to/your/ios-project/.mcp.json

# 3. 将 settings.local.json 复制到 .claude/ 目录
mkdir -p /path/to/your/ios-project/.claude
cp settings.local.json /path/to/your/ios-project/.claude/settings.local.json
```

### 场景 B：新机器首次安装（无代理）

```bash
# 1. 运行安装脚本
bash install.sh

# 2. 使用无代理版 mcp.json
cp mcp-no-proxy.json /path/to/your/ios-project/.mcp.json

# 3. 复制 settings.local.json
cp settings.local.json /path/to/your/ios-project/.claude/settings.local.json
```

### 场景 C：已安装 xcodebuildmcp，只需配置新项目

```bash
# 直接复制配置文件
cp mcp.json /path/to/your/ios-project/.mcp.json
cp settings.local.json /path/to/your/ios-project/.claude/settings.local.json
```

---

## 当前环境信息（提取自）

| 项目 | 值 |
|------|-----|
| xcodebuildmcp 版本 | 2.3.2 |
| node 版本 | 25.8.1 |
| node 路径 | `/opt/homebrew/bin/node` |
| npm 全局模块路径 | `/opt/homebrew/lib/node_modules/` |
| wrapper 安装路径 | `/opt/homebrew/bin/xcodebuildmcp-wrapper` |
| 代理配置 | 有（HTTP_PROXY=127.0.0.1:7897） |

---

## settings.local.json 权限说明

模板中包含的 MCP 工具权限（自动授权，无需每次确认）：

| 权限 | 用途 |
|------|------|
| `session_show_defaults` / `session_set_defaults` | 查看/设置会话默认参数 |
| `build_sim` / `build_run_sim` | 模拟器构建和运行 |
| `test_sim` | 模拟器测试 |
| `clean` | 清除构建缓存 |
| `list_sims` / `boot_sim` | 模拟器管理 |
| `screenshot` | 截图 |
| `start/stop_sim_log_cap` | 日志捕获 |
| `get_coverage_report` / `get_file_coverage` | 测试覆盖率 |
| `discover_projs` / `list_schemes` | 项目探索 |

> `settings.local.json` 不应提交到 git（加入 `.gitignore`），其中可能包含用户特定的临时权限。

---

## 迁移到其他机器时需调整

如果目标机器的 node/npm 路径不同（非 Homebrew 安装），需修改 `xcodebuildmcp-wrapper.sh` 中的路径：

```bash
# 查找实际路径
which node
npm root -g
```

然后更新 wrapper 最后两行的路径。
