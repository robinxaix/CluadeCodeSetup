# iOS 项目 Claude Code 配置指南

本指南记录了基于 XcodeGen + SwiftUI + gRPC-Web 技术栈的 iOS 项目 Claude Code 完整配置。  
如需在新项目中复用，将 `ai-setup-prompt.md` 的内容粘贴到项目根目录打开的 Claude Code 会话中，AI 会自动执行全部配置步骤。

**文件说明：**
- `README.md`（本文件）— 中文配置说明与参考手册
- `ai-setup-prompt.md` — AI 可直接执行的全量配置 prompt
- `xcodebuildmcp-setup.md` — XcodeBuildMCP 安装与排障专项指南

---

## 配置概览

| 层级 | 内容 | 位置 |
|------|------|------|
| 项目指令 | CLAUDE.md 补充构建命令和规范 | `.claude/`（项目级） |
| Slash 命令 | 7 个用户主动调用的任务快捷方式 | `.claude/commands/` |
| Agent Skills | 3 个自动激活的专家模式 | `.claude/skills/` |
| Subagents | 4 个专职 AI 子助手 | `.claude/agents/` |
| 输出风格 | 1 个教学导向的响应风格 | `.claude/output-styles/` |
| 个人命令 | `swift-style` 全局 lint 检查 | `~/.claude/commands/` |

---

## 配置后目录结构

```
<项目根目录>/
└── .claude/
    ├── commands/
    │   ├── build.md              # /build  — 智能构建项目
    │   ├── test.md               # /test   — 运行测试
    │   ├── run-app.md            # /run-app — 构建并在模拟器启动
    │   ├── create-view.md        # /create-view <ViewName>
    │   ├── refactor-view.md      # /refactor-view <文件>
    │   ├── fix-build.md          # /fix-build — 诊断并修复编译错误
    │   └── implement-feature.md  # /implement-feature <功能名>
    ├── skills/
    │   ├── ios-testing/          # 自动激活：处理 XCTest 相关工作时
    │   │   └── SKILL.md
    │   ├── code-analyzer/        # 自动激活：PR 审查/架构分析时
    │   │   └── SKILL.md
    │   └── swiftui-components/   # 自动激活：创建或重构 SwiftUI 视图时
    │       ├── SKILL.md
    │       ├── PATTERNS.md
    │       ├── REFERENCE.md
    │       └── templates/
    │           ├── view-template.swift
    │           └── viewmodel-template.swift
    ├── agents/
    │   ├── ios-architect.md      # 架构设计（opus 模型）
    │   ├── swift-reviewer.md     # 代码审查（sonnet 模型）
    │   ├── swiftui-specialist.md # 复杂 UI 实现（sonnet 模型）
    │   └── ios-researcher.md     # Apple API 研究（opus 模型）
    └── output-styles/
        └── ios-mentor.md         # /output-style ios-mentor

~/.claude/
└── commands/
    └── swift-style.md            # /swift-style — 全局 lint 命令（所有项目可用）
```

---

## Slash 命令说明

Slash 命令由用户**主动输入**触发，类似 IDE 的快捷指令。

### 构建与运行

| 命令 | 说明 |
|------|------|
| `/build` | 自动检测项目类型，为模拟器构建 |
| `/run-app` | 启动模拟器 → 构建 → 安装 → 启动 App → 捕获日志 |
| `/fix-build` | 全量构建 → 分析每个错误 → 逐一修复 → 验证成功 |

### 代码生成

| 命令 | 说明 |
|------|------|
| `/create-view <ViewName>` | 生成 `View.swift` + `ViewModel.swift` 骨架 |
| `/refactor-view <文件>` | 提取子视图、优化数据流 |
| `/implement-feature <功能名>` | 读取 spec → 实现当前任务 → 构建验证 |

### 测试与质量

| 命令 | 说明 |
|------|------|
| `/test` | 运行 App 目标或 Swift Package 的测试 |
| `/swift-style` | 运行 SwiftLint + swift-format 检查（全局命令） |

---

## Agent Skills 说明

Skills **自动激活**，无需手动调用。Claude 根据对话上下文判断是否激活。

| Skill | 自动激活时机 | 工具权限 |
|-------|------------|---------|
| `ios-testing` | 提及 XCTest、编写测试、讨论覆盖率 | 只读 + xcode test MCP 工具 |
| `code-analyzer` | 审查代码、分析架构、评估 PR | 只读（Read/Grep/Glob） |
| `swiftui-components` | 创建或重构 SwiftUI 视图 | 读写（Read/Write/Edit） |

**关键设计**：`code-analyzer` 仅有只读权限，物理上无法修改文件，即使 Claude 想改也无法执行——比靠 prompt 约束更安全。

---

## Subagents 说明

Subagents 是拥有**独立上下文窗口**的专职 AI，适合隔离复杂分析任务，避免污染主会话。

| Agent | 模型 | 适用场景 |
|-------|------|---------|
| `ios-architect` | opus | 设计数据层、评估架构、规划新功能 |
| `swift-reviewer` | sonnet | PR 审查、并发安全审计、内存管理检查 |
| `swiftui-specialist` | sonnet | 复杂布局、动画、自定义 Modifier |
| `ios-researcher` | opus | WWDC 查询、Apple API 版本兼容性研究 |

**模型选择逻辑**：分析/设计任务用 opus（更强推理），代码生成任务用 sonnet（速度与质量平衡）。

**显式调用示例**：
```
"用 ios-architect 帮我设计通知功能的数据层"
"让 swift-reviewer 审查这段 streaming 代码有没有数据竞争"
"请 ios-researcher 查一下 iOS 17 的 NavigationStack 深度链接方案"
```

---

## 输出风格说明

通过 `/output-style` 切换**会话级**响应风格，一次切换持续全程。

| 风格 | 命令 | 效果 |
|------|------|------|
| 默认 | `/output-style default` | 标准工程模式 |
| 解释型 | `/output-style explanatory` | 写代码前后添加 `★ Insight` 教学块 |
| 学习型 | `/output-style learning` | 添加 `TODO(human)` 引导开发者自己完成 |
| iOS 导师 | `/output-style ios-mentor` | 先讲"为什么"再讲"怎么做"，代码中插入 `// 💡 Learn:` 注释 |

---

## CLAUDE.md 新增内容说明

在项目 `CLAUDE.md` 末尾追加了 `## Build Commands` 章节，明确告知 Claude 优先使用 XcodeBuildMCP 工具（而非 shell 命令）执行构建、测试、清理等操作，保证 MCP 工具调用的一致性。

---

## 迁移到其他项目时需修改的部分

以下文件包含项目特定内容，迁移时需按新项目情况调整：

1. **`CLAUDE.md`** — 项目结构、技术栈、验证命令
2. **`ios-architect.md`** — 项目特有规则（如 gRPC 协议约束、导航模式）
3. **`swift-reviewer.md`** — 与新项目架构规范一致的审查标准
4. **`swiftui-components/PATTERNS.md`** — 新项目使用的 ViewModel/View 模式
5. **`swiftui-components/REFERENCE.md`** — iOS 最低版本约束

**无需修改**（项目无关）：`/build`、`/test`、`/run-app`、`/swift-style`、`ios-researcher`。
